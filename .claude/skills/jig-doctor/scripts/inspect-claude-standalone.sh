#!/usr/bin/env sh
set -eu

ROOT=
SCOPE=

error() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: sh inspect-claude-standalone.sh --root <.claude/skills path> --scope <project|user>
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      shift
      [ "$#" -gt 0 ] || error "--root requires a path"
      ROOT="$1"
      ;;
    --scope)
      shift
      [ "$#" -gt 0 ] || error "--scope requires project or user"
      SCOPE="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) error "unknown option: $1" ;;
  esac
  shift
done

[ -n "$ROOT" ] || error "--root is required"
case "$SCOPE" in
  project|user) ;;
  *) error "scope must be project or user: $SCOPE" ;;
esac
case "$ROOT" in
  .claude/skills|./.claude/skills|*/.claude/skills) ;;
  *) error "root must be a project or user .claude/skills directory: $ROOT" ;;
esac

printf 'scope=%s\n' "$SCOPE"
if [ ! -d "$ROOT" ]; then
  printf 'root=%s\nstatus=absent\nversion=none\nskills=none\n' "$ROOT"
  exit 0
fi

ROOT=$(cd "$ROOT" && pwd -P)
printf 'root=%s\n' "$ROOT"

ROOT_OWNER=$(cd "$ROOT/../.." && pwd -P)
if [ -f "$ROOT_OWNER/manifest.tsv" ] \
  && [ -f "$ROOT_OWNER/skills/jig-update/SKILL.md" ] \
  && [ -f "$ROOT_OWNER/scripts/build-dist.sh" ]; then
  printf 'status=source-mirror\nversion=development\nskills=development\n'
  exit 0
fi

frontmatter_name() {
  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^name: / { sub(/^name: /, ""); print; exit }
  ' "$1"
}

LEDGER="$ROOT/.jig-installation"
ledger_value() {
  ledger_key="$1"
  sed -n "s/^$ledger_key=//p" "$LEDGER" | head -n 1
}

validate_ledger_mappings() {
  ledger_mappings=$(ledger_value skills | tr ',' ' ')
  [ -n "$ledger_mappings" ] || return 1
  ledger_has_update=0
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
    if [ "$ledger_skill" = jig-update ] && [ "$ledger_directory" = jig-update ]; then
      ledger_has_update=1
    fi
  done
  [ "$ledger_has_update" -eq 1 ]
}

validate_ledger() {
  [ -f "$LEDGER" ] && [ ! -L "$LEDGER" ] \
    && [ "$(wc -l < "$LEDGER" | tr -d ' ')" = 6 ] \
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
    && validate_ledger_mappings
}

validate_provenance() {
  provenance_path="$1"
  provenance_skill="$2"
  provenance_directory="$3"
  [ -f "$provenance_path" ] && [ ! -L "$provenance_path" ] \
    && [ "$(wc -l < "$provenance_path" | tr -d ' ')" = 4 ] \
    && grep -Fx 'format=1' "$provenance_path" >/dev/null 2>&1 \
    && grep -Fx 'repository=0x0w1/jig' "$provenance_path" >/dev/null 2>&1 \
    && grep -Fx "skill=$provenance_skill" "$provenance_path" >/dev/null 2>&1 \
    && grep -Fx "directory=$provenance_directory" "$provenance_path" >/dev/null 2>&1
}

if [ -e "$LEDGER" ] || [ -L "$LEDGER" ]; then
  if ! validate_ledger; then
    printf 'status=ledger-invalid\nversion=unknown\nskills=unknown\n'
    printf 'finding=invalid-ledger:%s\n' "$LEDGER"
    exit 0
  fi

  VERSION=$(ledger_value version)
  SKILLS=$(ledger_value skills)
  STATUS=verified
  for mapping in $(printf '%s' "$SKILLS" | tr ',' ' '); do
    skill=${mapping%%=*}
    directory=${mapping#*=}
    skill_root="$ROOT/$directory"
    provenance="$skill_root/.jig-provenance"

    if [ ! -d "$skill_root" ] || [ -L "$skill_root" ]; then
      [ "$STATUS" = provenance-conflict ] || STATUS=partial
      printf 'finding=missing-or-unsafe-skill-directory:%s\n' "$directory"
      continue
    fi
    if [ ! -f "$skill_root/SKILL.md" ] || [ -L "$skill_root/SKILL.md" ]; then
      [ "$STATUS" = provenance-conflict ] || STATUS=partial
      printf 'finding=missing-or-unsafe-skill-entry:%s\n' "$directory"
    fi
    if [ ! -e "$provenance" ] && [ ! -L "$provenance" ]; then
      [ "$STATUS" = provenance-conflict ] || STATUS=partial
      printf 'finding=missing-provenance:%s\n' "$directory"
    elif ! validate_provenance "$provenance" "$skill" "$directory"; then
      STATUS=provenance-conflict
      printf 'finding=invalid-provenance:%s\n' "$directory"
    fi
  done

  printf 'status=%s\nversion=%s\nskills=%s\n' "$STATUS" "$VERSION" "$SKILLS"
  exit 0
fi

SENTINEL="$ROOT/jig-update/SKILL.md"
if [ -f "$SENTINEL" ] && [ ! -L "$SENTINEL" ] \
  && [ "$(frontmatter_name "$SENTINEL")" = jig-update ] \
  && grep -Fx '# jig Update' "$SENTINEL" >/dev/null 2>&1 \
  && grep -F '0x0w1/jig' "$SENTINEL" >/dev/null 2>&1; then
  printf 'status=legacy-unledgered\nversion=unknown\nskills=unknown\n'
  exit 0
fi

printf 'status=non-owned\nversion=none\nskills=none\n'
