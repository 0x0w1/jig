#!/usr/bin/env sh
set -eu

REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
mkdir -p "$TEST_ROOT/project"

(
  cd "$TEST_ROOT/project"
  REPO_RAW_URL="file://$REPOSITORY_ROOT" \
    sh "$REPOSITORY_ROOT/install.sh" \
      --target codex \
      --scope project \
      --skills project-setup,jig-setup \
      > "$TEST_ROOT/install.log"
)

grep -Fx 'jig [info] Selected skills: jig-setup' "$TEST_ROOT/install.log" >/dev/null
test -f "$TEST_ROOT/project/.agents/skills/jig-setup/SKILL.md"
test ! -e "$TEST_ROOT/project/.agents/skills/jig-project-setup"
grep -F '<!-- jig:version custom skills=jig-setup -->' "$TEST_ROOT/project/AGENTS.md" >/dev/null

printf '%s\n' 'installer skill alias tests ok'
