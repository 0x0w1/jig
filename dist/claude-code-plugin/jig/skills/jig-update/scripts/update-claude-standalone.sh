#!/usr/bin/env sh
set -eu

ROOT=
VERSION=
SCOPE=
DRY_RUN=0
TEMP_ROOT=
TRANSACTION_ACTIVE=0
TRANSACTION_STATE=
TRANSACTION_DIRS=

log() {
  printf '%s\n' "$*"
}

error() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: sh update-claude-standalone.sh --root <.claude/skills path> --version <vX.Y.Z> [--scope <project|user>] [--dry-run]
EOF
}

rollback_changes() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 0

  log "ROLLBACK restoring standalone installation: $ROOT"
  rollback_failed=0
  while IFS="	" read -r state_id destination destination_existed backup_existed; do
    [ -n "$state_id" ] || continue
    if [ "$destination_existed" -eq 1 ]; then
      if ! mkdir -p "$(dirname "$destination")" >/dev/null 2>&1 \
        || ! cp "$TEMP_ROOT/rollback/$state_id.destination" "$destination" >/dev/null 2>&1; then
        printf 'ERROR: rollback could not restore %s\n' "$destination" >&2
        rollback_failed=1
      fi
    else
      if ! rm -f "$destination" >/dev/null 2>&1; then
        printf 'ERROR: rollback could not remove %s\n' "$destination" >&2
        rollback_failed=1
      fi
    fi

    if [ "$backup_existed" -eq 1 ]; then
      if ! cp "$TEMP_ROOT/rollback/$state_id.backup" "$destination.bak" >/dev/null 2>&1; then
        printf 'ERROR: rollback could not restore %s.bak\n' "$destination" >&2
        rollback_failed=1
      fi
    else
      if ! rm -f "$destination.bak" >/dev/null 2>&1; then
        printf 'ERROR: rollback could not remove %s.bak\n' "$destination" >&2
        rollback_failed=1
      fi
    fi
  done < "$TRANSACTION_STATE"

  if [ -s "$TRANSACTION_DIRS" ]; then
    awk '{ print length($0) "\t" $0 }' "$TRANSACTION_DIRS" \
      | sort -rn \
      | cut -f 2- > "$TEMP_ROOT/rollback-directories.txt"
    while IFS= read -r created_directory; do
      [ -n "$created_directory" ] || continue
      if ! rmdir "$created_directory" >/dev/null 2>&1 && [ -d "$created_directory" ]; then
        printf 'ERROR: rollback could not remove directory %s\n' "$created_directory" >&2
        rollback_failed=1
      fi
    done < "$TEMP_ROOT/rollback-directories.txt"
  fi
  if [ "$rollback_failed" -eq 1 ]; then
    printf 'ERROR: rollback was incomplete; inspect the standalone root before retrying: %s\n' "$ROOT" >&2
  fi
  TRANSACTION_ACTIVE=0
}

cleanup() {
  cleanup_status=$?
  trap - EXIT HUP INT TERM
  rollback_changes
  [ -z "$TEMP_ROOT" ] || rm -rf "$TEMP_ROOT"
  exit "$cleanup_status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      shift
      [ "$#" -gt 0 ] || error "--root requires a path"
      ROOT="$1"
      ;;
    --version)
      shift
      [ "$#" -gt 0 ] || error "--version requires a release tag"
      VERSION="$1"
      ;;
    --scope)
      shift
      [ "$#" -gt 0 ] || error "--scope requires project or user"
      SCOPE="$1"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "unknown option: $1"
      ;;
  esac
  shift
done

[ -n "$ROOT" ] || error "--root is required"
[ -n "$VERSION" ] || error "--version is required"

case "$ROOT" in
  .claude/skills|./.claude/skills|*/.claude/skills) ;;
  *) error "root must be a project or user .claude/skills directory: $ROOT" ;;
esac

case "$VERSION" in
  *[!A-Za-z0-9._-]*|'') error "invalid version: $VERSION" ;;
esac

[ -d "$ROOT" ] || error "standalone skill root does not exist: $ROOT"
ROOT=$(cd "$ROOT" && pwd -P)

if [ -z "$SCOPE" ]; then
  USER_SKILL_ROOT=$(cd "${HOME:?}" && pwd -P)/.claude/skills
  if [ "$ROOT" = "$USER_SKILL_ROOT" ]; then
    SCOPE=user
  else
    SCOPE=project
  fi
fi
case "$SCOPE" in
  project|user) ;;
  *) error "scope must be project or user: $SCOPE" ;;
esac

ROOT_OWNER=$(cd "$ROOT/../.." && pwd -P)
CURRENT_DIRECTORY=$(pwd -P)
if [ "$ROOT_OWNER" = "$CURRENT_DIRECTORY" ] \
  && [ -f "$CURRENT_DIRECTORY/manifest.tsv" ] \
  && [ -f "$CURRENT_DIRECTORY/skills/jig-update/SKILL.md" ] \
  && [ -f "$CURRENT_DIRECTORY/scripts/build-dist.sh" ]; then
  error "refusing to replace the jig source repository's .claude/skills development mirror"
fi

frontmatter_name() {
  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^name: / { sub(/^name: /, ""); print; exit }
  ' "$1"
}

canonical_title() {
  sed -n '/^# / { p; q; }' "$1"
}

write_provenance() {
  provenance_destination="$1"
  provenance_skill="$2"
  provenance_directory="$3"
  printf '%s\n' \
    'format=1' \
    'repository=0x0w1/jig' \
    "skill=$provenance_skill" \
    "directory=$provenance_directory" \
    > "$provenance_destination"
}

provenance_is_valid() {
  provenance_path="$1"
  provenance_skill="$2"
  provenance_directory="$3"
  provenance_expected="$TEMP_ROOT/provenance-check"
  write_provenance "$provenance_expected" "$provenance_skill" "$provenance_directory"
  cmp -s "$provenance_expected" "$provenance_path"
}

LEDGER="$ROOT/.jig-installation"
ledger_value() {
  ledger_key="$1"
  sed -n "s/^$ledger_key=//p" "$LEDGER" | head -n 1
}

validate_ledger() {
  [ -f "$LEDGER" ] || return 1
  [ "$(wc -l < "$LEDGER" | tr -d ' ')" = 6 ] \
    && [ "$(grep -c '^format=' "$LEDGER")" = 1 ] \
    && [ "$(grep -c '^repository=' "$LEDGER")" = 1 ] \
    && [ "$(grep -c '^version=' "$LEDGER")" = 1 ] \
    && [ "$(grep -c '^target=' "$LEDGER")" = 1 ] \
    && [ "$(grep -c '^scope=' "$LEDGER")" = 1 ] \
    && [ "$(grep -c '^skills=' "$LEDGER")" = 1 ] \
    && [ "$(ledger_value format)" = 1 ] \
    && [ "$(ledger_value repository)" = 0x0w1/jig ] \
    && [ "$(ledger_value target)" = claude-code ] \
    && [ "$(ledger_value scope)" = "$SCOPE" ] \
    && [ -n "$(ledger_value version)" ] \
    && [ -n "$(ledger_value skills)" ] \
    && validate_ledger_mappings
}

validate_ledger_mappings() {
  ledger_mappings=$(ledger_value skills | tr ',' ' ')
  [ -n "$ledger_mappings" ] || return 1
  for ledger_mapping in $ledger_mappings; do
    case "$ledger_mapping" in
      *=*) ;;
      *) return 1 ;;
    esac
    ledger_skill=${ledger_mapping%%=*}
    ledger_directory=${ledger_mapping#*=}
    case "$ledger_skill:$ledger_directory" in
      *[!A-Za-z0-9._:-]*|:*|*:) return 1 ;;
    esac
    case "$ledger_directory" in
      *=*) return 1 ;;
    esac
  done
}

ledger_owns_mapping() {
  ledger_mapping="$1=$2"
  ledger_value skills | tr ',' '\n' | grep -Fx "$ledger_mapping" >/dev/null 2>&1
}

LEDGER_PRESENT=0
if [ -e "$LEDGER" ]; then
  [ -f "$LEDGER" ] || error "standalone installation ledger is not a regular file: $LEDGER"
  validate_ledger || error "standalone installation ledger is malformed or belongs to another scope: $LEDGER"
  LEDGER_PRESENT=1
  log "INSTALLED_VERSION $(ledger_value version) scope=$SCOPE"
else
  log "INSTALLED_VERSION unknown scope=$SCOPE"
fi

SENTINEL="$ROOT/jig-update/SKILL.md"
[ -f "$SENTINEL" ] || error "not a standalone jig installation: missing $SENTINEL"
if [ "$LEDGER_PRESENT" -eq 1 ]; then
  ledger_owns_mapping jig-update jig-update \
    || error "standalone installation ledger does not own jig-update"
else
  [ "$(frontmatter_name "$SENTINEL")" = jig-update ] \
    || error "not a standalone jig installation: jig-update name marker is missing"
  grep -Fx '# jig Update' "$SENTINEL" >/dev/null 2>&1 \
    || error "not a standalone jig installation: jig-update title marker is missing"
  grep -F '0x0w1/jig' "$SENTINEL" >/dev/null 2>&1 \
    || error "not a standalone jig installation: jig provenance is missing"
fi

TEMP_ROOT=$(mktemp -d)
MANIFEST="$TEMP_ROOT/manifest.tsv"
FILES="$TEMP_ROOT/files.tsv"
SELECTIONS="$TEMP_ROOT/selections.tsv"
APPLY_PLAN="$TEMP_ROOT/apply.tsv"
TRANSACTION_STATE="$TEMP_ROOT/transaction-state.tsv"
TRANSACTION_DIRS="$TEMP_ROOT/transaction-dirs.txt"
: > "$SELECTIONS"
: > "$APPLY_PLAN"
: > "$TRANSACTION_STATE"
: > "$TRANSACTION_DIRS"

RAW_ROOT=${JIG_UPDATE_RAW_BASE_URL:-https://raw.githubusercontent.com/0x0w1/jig}
RELEASE_ROOT="${RAW_ROOT%/}/$VERSION"

curl -fsSL "$RELEASE_ROOT/dist/manifest.tsv" -o "$MANIFEST" \
  || error "could not download manifest for $VERSION"
if ! curl -fsSL "$RELEASE_ROOT/dist/files.tsv" -o "$FILES"; then
  : > "$FILES"
fi

source_url() {
  source_skill="$1"
  source_directory="$2"
  source_relative="$3"
  if [ "$source_directory" = "$source_skill" ]; then
    printf '%s/dist/claude-code-plugin/jig/skills/%s/%s\n' "$RELEASE_ROOT" "$source_skill" "$source_relative"
  else
    printf '%s/dist/codex/.agents/skills/%s/%s\n' "$RELEASE_ROOT" "$source_directory" "$source_relative"
  fi
}

FOUND=0
VERIFIED=0

for skill in $(awk -F '\t' '!/^#/ && NF >= 1 { print $1 }' "$MANIFEST"); do
  case "$skill" in
    jig-*) prefixed="$skill" ;;
    *) prefixed="jig-$skill" ;;
  esac

  candidates="$skill"
  [ "$prefixed" = "$skill" ] || candidates="$candidates $prefixed"

  for directory_name in $candidates; do
    skill_root="$ROOT/$directory_name"
    [ -d "$skill_root" ] || continue
    FOUND=$((FOUND + 1))

    if [ "$LEDGER_PRESENT" -eq 1 ] && ! ledger_owns_mapping "$skill" "$directory_name"; then
      log "SKIP skill directory not owned by installation ledger: $skill_root"
      continue
    fi

    canonical_entry="$TEMP_ROOT/canonical-$FOUND"
    canonical_url=$(source_url "$skill" "$directory_name" SKILL.md)
    curl -fsSL "$canonical_url" -o "$canonical_entry" \
      || error "could not download $canonical_url"

    skill_entry="$skill_root/SKILL.md"
    provenance="$skill_root/.jig-provenance"
    if [ -e "$provenance" ]; then
      [ -f "$provenance" ] || error "skill provenance is not a regular file: $provenance"
      if ! provenance_is_valid "$provenance" "$skill" "$directory_name"; then
        if [ "$LEDGER_PRESENT" -eq 1 ]; then
          error "installed skill provenance conflicts with the installation ledger: $skill_root"
        fi
        log "SKIP skill directory with invalid provenance: $skill_root"
        continue
      fi
    else
      expected_title=$(canonical_title "$canonical_entry")
      installed_title=
      [ ! -f "$skill_entry" ] || installed_title=$(canonical_title "$skill_entry")
      if [ ! -f "$skill_entry" ] \
        || [ "$(frontmatter_name "$skill_entry")" != "$directory_name" ] \
        || [ -z "$expected_title" ] \
        || [ "$installed_title" != "$expected_title" ]; then
        log "SKIP ambiguous markerless skill directory: $skill_root"
        continue
      fi
    fi

    VERIFIED=$((VERIFIED + 1))
    printf '%s\t%s\n' "$skill" "$directory_name" >> "$SELECTIONS"
  done
done

[ "$FOUND" -gt 0 ] || error "no installed jig skills matched the release manifest"
[ "$VERIFIED" -gt 0 ] || error "no installed skill directory has verifiable jig ownership"
awk -F '\t' '$1 == "jig-update" && $2 == "jig-update" { found = 1 } END { exit found ? 0 : 1 }' "$SELECTIONS" \
  || error "the jig-update sentinel directory was not safely verified"

PLAN_COUNT=0
while IFS="	" read -r skill directory_name; do
  [ -n "$skill" ] || continue
  skill_root="$ROOT/$directory_name"
  expected="$TEMP_ROOT/expected-$VERIFIED-$PLAN_COUNT"
  awk -F '\t' -v selected="$skill" '$1 == selected { print $2 }' "$FILES" > "$expected"
  [ -s "$expected" ] || printf 'SKILL.md\n' > "$expected"

  while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue
    PLAN_COUNT=$((PLAN_COUNT + 1))
    staged="$TEMP_ROOT/staged-$PLAN_COUNT"
    payload_url=$(source_url "$skill" "$directory_name" "$relative_path")
    curl -fsSL "$payload_url" -o "$staged" \
      || error "could not download $payload_url"
    destination="$skill_root/$relative_path"

    if [ -f "$destination" ] && cmp -s "$staged" "$destination"; then
      log "PASS unchanged file: $destination"
    else
      printf '%s\t%s\n' "$destination" "$staged" >> "$APPLY_PLAN"
    fi
  done < "$expected"

  PLAN_COUNT=$((PLAN_COUNT + 1))
  staged_provenance="$TEMP_ROOT/staged-$PLAN_COUNT"
  write_provenance "$staged_provenance" "$skill" "$directory_name"
  if [ -f "$skill_root/.jig-provenance" ] \
    && cmp -s "$staged_provenance" "$skill_root/.jig-provenance"; then
    log "PASS unchanged provenance: $skill_root/.jig-provenance"
  else
    printf '%s\t%s\n' "$skill_root/.jig-provenance" "$staged_provenance" >> "$APPLY_PLAN"
  fi

  find "$skill_root" -type f ! -name '*.bak' ! -name '.jig-provenance' | while IFS= read -r installed_file; do
    relative_file=${installed_file#"$skill_root/"}
    if ! grep -Fx "$relative_file" "$expected" >/dev/null 2>&1; then
      log "LEFTOVER $installed_file"
    fi
  done
done < "$SELECTIONS"

SKILLS_VALUE=$(awk -F '\t' '
  BEGIN { separator = "" }
  { printf "%s%s=%s", separator, $1, $2; separator = "," }
  END { print "" }
' "$SELECTIONS")
PLAN_COUNT=$((PLAN_COUNT + 1))
STAGED_LEDGER="$TEMP_ROOT/staged-$PLAN_COUNT"
printf '%s\n' \
  'format=1' \
  'repository=0x0w1/jig' \
  "version=$VERSION" \
  'target=claude-code' \
  "scope=$SCOPE" \
  "skills=$SKILLS_VALUE" \
  > "$STAGED_LEDGER"
if [ -f "$LEDGER" ] && cmp -s "$STAGED_LEDGER" "$LEDGER"; then
  log "PASS unchanged installation ledger: $LEDGER"
else
  printf '%s\t%s\n' "$LEDGER" "$STAGED_LEDGER" >> "$APPLY_PLAN"
fi

if [ ! -s "$APPLY_PLAN" ]; then
  log "PASS standalone installation already matches $VERSION: $ROOT"
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  while IFS="	" read -r destination staged; do
    [ -n "$destination" ] || continue
    log "PLAN update file: $destination"
  done < "$APPLY_PLAN"
  exit 0
fi

mkdir -p "$TEMP_ROOT/rollback"
state_id=0
while IFS="	" read -r destination staged; do
  [ -n "$destination" ] || continue
  state_id=$((state_id + 1))
  destination_existed=0
  backup_existed=0
  if [ -e "$destination" ]; then
    [ -f "$destination" ] || error "update destination is not a regular file: $destination"
    destination_existed=1
    cp "$destination" "$TEMP_ROOT/rollback/$state_id.destination" \
      || error "could not stage rollback copy for $destination"
  fi
  if [ -e "$destination.bak" ]; then
    [ -f "$destination.bak" ] || error "backup destination is not a regular file: $destination.bak"
    backup_existed=1
    cp "$destination.bak" "$TEMP_ROOT/rollback/$state_id.backup" \
      || error "could not stage rollback copy for $destination.bak"
  fi
  printf '%s\t%s\t%s\t%s\n' \
    "$state_id" "$destination" "$destination_existed" "$backup_existed" \
    >> "$TRANSACTION_STATE"

  missing_parent=$(dirname "$destination")
  while [ ! -e "$missing_parent" ] && [ "$missing_parent" != "$ROOT" ]; do
    printf '%s\n' "$missing_parent" >> "$TRANSACTION_DIRS"
    missing_parent=$(dirname "$missing_parent")
  done
done < "$APPLY_PLAN"
sort -u "$TRANSACTION_DIRS" -o "$TRANSACTION_DIRS"

TRANSACTION_ACTIVE=1
while IFS="	" read -r destination staged; do
  [ -n "$destination" ] || continue
  mkdir -p "$(dirname "$destination")" \
    || error "could not create destination directory for $destination"
  if [ -f "$destination" ]; then
    cp "$destination" "$destination.bak" \
      || error "could not back up $destination"
  fi
  cp "$staged" "$destination" \
    || error "could not install $destination"
  log "UPDATED $destination"
done < "$APPLY_PLAN"
TRANSACTION_ACTIVE=0

log "UPDATED_VERSION $VERSION scope=$SCOPE skills=$SKILLS_VALUE"
