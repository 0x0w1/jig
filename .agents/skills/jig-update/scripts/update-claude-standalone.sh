#!/usr/bin/env sh
set -eu

ROOT=
VERSION=
DRY_RUN=0

log() {
  printf '%s\n' "$*"
}

error() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: sh update-claude-standalone.sh --root <.claude/skills path> --version <vX.Y.Z> [--dry-run]
EOF
}

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

ROOT_OWNER=$(cd "$ROOT/../.." && pwd -P)
CURRENT_DIRECTORY=$(pwd -P)
if [ "$ROOT_OWNER" = "$CURRENT_DIRECTORY" ] \
  && [ -f "$CURRENT_DIRECTORY/manifest.tsv" ] \
  && [ -f "$CURRENT_DIRECTORY/skills/jig-update/SKILL.md" ] \
  && [ -f "$CURRENT_DIRECTORY/scripts/build-dist.sh" ]; then
  error "refusing to replace the jig source repository's .claude/skills development mirror"
fi

SENTINEL="$ROOT/jig-update/SKILL.md"
[ -f "$SENTINEL" ] || error "not a standalone jig installation: missing $SENTINEL"
grep -Fx 'name: jig-update' "$SENTINEL" >/dev/null 2>&1 \
  || error "not a standalone jig installation: jig-update name marker is missing"
grep -Fx '# jig Update' "$SENTINEL" >/dev/null 2>&1 \
  || error "not a standalone jig installation: jig-update title marker is missing"
grep -F '0x0w1/jig' "$SENTINEL" >/dev/null 2>&1 \
  || error "not a standalone jig installation: jig provenance is missing"

TEMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

RAW_ROOT=${JIG_UPDATE_RAW_BASE_URL:-https://raw.githubusercontent.com/0x0w1/jig}
RELEASE_ROOT="${RAW_ROOT%/}/$VERSION"
MANIFEST="$TEMP_ROOT/manifest.tsv"
FILES="$TEMP_ROOT/files.tsv"

curl -fsSL "$RELEASE_ROOT/dist/manifest.tsv" -o "$MANIFEST" \
  || error "could not download manifest for $VERSION"
if ! curl -fsSL "$RELEASE_ROOT/dist/files.tsv" -o "$FILES"; then
  : > "$FILES"
fi

FOUND=0

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

    skill_entry="$skill_root/SKILL.md"
    if [ ! -f "$skill_entry" ] || ! grep -Fx "name: $directory_name" "$skill_entry" >/dev/null 2>&1; then
      log "SKIP unverified skill directory: $skill_root"
      continue
    fi

    expected="$TEMP_ROOT/expected-$FOUND"
    awk -F '\t' -v selected="$skill" '$1 == selected { print $2 }' "$FILES" > "$expected"
    [ -s "$expected" ] || printf 'SKILL.md\n' > "$expected"

    while IFS= read -r relative_path; do
      [ -n "$relative_path" ] || continue
      destination="$skill_root/$relative_path"
      download="$TEMP_ROOT/download-$FOUND"
      mkdir -p "$(dirname "$download")"

      if [ "$directory_name" = "$skill" ]; then
        source_url="$RELEASE_ROOT/dist/claude-code-plugin/jig/skills/$skill/$relative_path"
      else
        source_url="$RELEASE_ROOT/dist/codex/.agents/skills/$directory_name/$relative_path"
      fi

      curl -fsSL "$source_url" -o "$download" \
        || error "could not download $source_url"

      if [ -f "$destination" ] && cmp -s "$download" "$destination"; then
        log "PASS unchanged file: $destination"
        continue
      fi

      if [ "$DRY_RUN" -eq 1 ]; then
        log "PLAN update file: $destination"
        continue
      fi

      mkdir -p "$(dirname "$destination")"
      if [ -f "$destination" ]; then
        cp "$destination" "$destination.bak"
      fi
      cp "$download" "$destination"
      log "UPDATED $destination"
    done < "$expected"

    find "$skill_root" -type f ! -name '*.bak' | while IFS= read -r installed_file; do
      relative_file=${installed_file#"$skill_root/"}
      if ! grep -Fx "$relative_file" "$expected" >/dev/null 2>&1; then
        log "LEFTOVER $installed_file"
      fi
    done
  done
done

[ "$FOUND" -gt 0 ] || error "no installed jig skills matched the release manifest"
