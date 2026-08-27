#!/usr/bin/env sh
set -eu

SCRIPT=skills/jig-update/scripts/update-claude-standalone.sh
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

VERSION=v9.9.9
PAYLOAD="$TEST_ROOT/payload/$VERSION"

mkdir -p \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/scripts" \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync" \
  "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync"

printf '%s\n' \
  'jig-update	solo-cli	yes' \
  'github-sync	solo-cli	yes' \
  'project-setup	solo-cli	yes' \
  > "$PAYLOAD/dist/manifest.tsv"

printf '%s\n' \
  '# skill	path' \
  'jig-update	SKILL.md' \
  'jig-update	scripts/new-helper.sh' \
  'github-sync	SKILL.md' \
  > "$PAYLOAD/dist/files.tsv"

printf '%s\n' \
  '---' \
  'name: jig-update' \
  '---' \
  '# jig Update' \
  'Repository: 0x0w1/jig' \
  'new standalone updater' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/SKILL.md"
printf '%s\n' '#!/usr/bin/env sh' 'printf helper' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/scripts/new-helper.sh"

printf '%s\n' \
  '---' \
  'name: github-sync' \
  '---' \
  '# GitHub Sync' \
  'new unprefixed payload' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync/SKILL.md"

printf '%s\n' \
  '---' \
  'name: jig-github-sync' \
  '---' \
  '# GitHub Sync' \
  'new prefixed payload' \
  > "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync/SKILL.md"

PROJECT_SKILLS="$TEST_ROOT/project/.claude/skills"
mkdir -p "$PROJECT_SKILLS/jig-update" "$PROJECT_SKILLS/github-sync" "$PROJECT_SKILLS/personal-skill"

printf '%s\n' \
  '---' \
  'name: jig-update' \
  '---' \
  '# jig Update' \
  'Repository: 0x0w1/jig' \
  'old standalone updater' \
  > "$PROJECT_SKILLS/jig-update/SKILL.md"
printf '%s\n' '---' 'name: github-sync' '---' 'old unprefixed payload' \
  > "$PROJECT_SKILLS/github-sync/SKILL.md"
printf '%s\n' 'personal content' > "$PROJECT_SKILLS/personal-skill/SKILL.md"

JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$PROJECT_SKILLS" --version "$VERSION" >/dev/null

cmp -s \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync/SKILL.md" \
  "$PROJECT_SKILLS/github-sync/SKILL.md"
grep -F 'old unprefixed payload' "$PROJECT_SKILLS/github-sync/SKILL.md.bak" >/dev/null
grep -F 'printf helper' "$PROJECT_SKILLS/jig-update/scripts/new-helper.sh" >/dev/null
grep -F 'personal content' "$PROJECT_SKILLS/personal-skill/SKILL.md" >/dev/null
[ ! -e "$PROJECT_SKILLS/project-setup" ]

USER_SKILLS="$TEST_ROOT/user/.claude/skills"
mkdir -p "$USER_SKILLS/jig-update" "$USER_SKILLS/jig-github-sync"
cp "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" "$USER_SKILLS/jig-update/SKILL.md"
printf '%s\n' '---' 'name: jig-github-sync' '---' 'old prefixed payload' \
  > "$USER_SKILLS/jig-github-sync/SKILL.md"

JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$USER_SKILLS" --version "$VERSION" >/dev/null

cmp -s \
  "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync/SKILL.md" \
  "$USER_SKILLS/jig-github-sync/SKILL.md"
grep -F 'old prefixed payload' "$USER_SKILLS/jig-github-sync/SKILL.md.bak" >/dev/null

UNOWNED_SKILLS="$TEST_ROOT/unowned/.claude/skills"
mkdir -p "$UNOWNED_SKILLS/github-sync"
printf '%s\n' 'user-owned content' > "$UNOWNED_SKILLS/github-sync/SKILL.md"

if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$UNOWNED_SKILLS" --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted an unowned skill root' >&2
  exit 1
fi
grep -F 'user-owned content' "$UNOWNED_SKILLS/github-sync/SKILL.md" >/dev/null

if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root .claude/skills --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted the jig source development mirror' >&2
  exit 1
fi

printf '%s\n' 'claude standalone update tests ok'
