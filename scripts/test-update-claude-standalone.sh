#!/usr/bin/env sh
set -eu

SCRIPT=skills/jig-update/scripts/update-claude-standalone.sh
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

VERSION=v9.9.9
PAYLOAD="$TEST_ROOT/payload/$VERSION"

mkdir -p \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/scripts" \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/blocked" \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync" \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/project-setup" \
  "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync"

printf '%b\n' \
  'jig-update\tsolo-cli\tyes' \
  'github-sync\tsolo-cli\tyes' \
  'project-setup\tsolo-cli\tyes' \
  > "$PAYLOAD/dist/manifest.tsv"

printf '%b\n' \
  '# skill\tpath' \
  'jig-update\tSKILL.md' \
  'jig-update\tscripts/new-helper.sh' \
  'jig-update\tblocked/file.sh' \
  'github-sync\tSKILL.md' \
  'project-setup\tSKILL.md' \
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
printf '%s\n' '#!/usr/bin/env sh' 'printf blocked fixture' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/blocked/file.sh"

printf '%s\n' \
  '---' \
  'name: github-sync' \
  '---' \
  '# GitHub Sync' \
  'new unprefixed payload' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync/SKILL.md"

printf '%s\n' \
  '---' \
  'name: project-setup' \
  '---' \
  '# Project Setup' \
  'new project setup payload' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/project-setup/SKILL.md"

printf '%s\n' \
  '---' \
  'name: jig-github-sync' \
  '---' \
  '# GitHub Sync' \
  'new prefixed payload' \
  > "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync/SKILL.md"

write_legacy_jig_update() {
  legacy_destination="$1"
  printf '%s\n' \
    '---' \
    'name: jig-update' \
    '---' \
    '# jig Update' \
    'Repository: 0x0w1/jig' \
    'old standalone updater' \
    > "$legacy_destination"
}

PROJECT_SKILLS="$TEST_ROOT/project/.claude/skills"
mkdir -p \
  "$PROJECT_SKILLS/jig-update" \
  "$PROJECT_SKILLS/github-sync" \
  "$PROJECT_SKILLS/project-setup" \
  "$PROJECT_SKILLS/personal-skill"

write_legacy_jig_update "$PROJECT_SKILLS/jig-update/SKILL.md"
printf '%s\n' '---' 'name: github-sync' '---' '# GitHub Sync' 'old unprefixed payload' \
  > "$PROJECT_SKILLS/github-sync/SKILL.md"
printf '%s\n' '---' 'name: project-setup' '---' '# Personal Project Setup' 'user-owned content' \
  > "$PROJECT_SKILLS/project-setup/SKILL.md"
printf '%s\n' 'personal content' > "$PROJECT_SKILLS/personal-skill/SKILL.md"

PROJECT_OUTPUT="$TEST_ROOT/project-update.log"
JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$PROJECT_SKILLS" --scope project --version "$VERSION" \
  > "$PROJECT_OUTPUT"

cmp -s \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync/SKILL.md" \
  "$PROJECT_SKILLS/github-sync/SKILL.md"
grep -F 'old unprefixed payload' "$PROJECT_SKILLS/github-sync/SKILL.md.bak" >/dev/null
grep -F 'printf helper' "$PROJECT_SKILLS/jig-update/scripts/new-helper.sh" >/dev/null
grep -F 'user-owned content' "$PROJECT_SKILLS/project-setup/SKILL.md" >/dev/null
[ ! -e "$PROJECT_SKILLS/project-setup/.jig-provenance" ]
grep -F 'personal content' "$PROJECT_SKILLS/personal-skill/SKILL.md" >/dev/null

grep -Fx 'repository=0x0w1/jig' "$PROJECT_SKILLS/jig-update/.jig-provenance" >/dev/null
grep -Fx 'skill=github-sync' "$PROJECT_SKILLS/github-sync/.jig-provenance" >/dev/null
grep -Fx 'version=v9.9.9' "$PROJECT_SKILLS/.jig-installation" >/dev/null
grep -Fx 'target=claude-code' "$PROJECT_SKILLS/.jig-installation" >/dev/null
grep -Fx 'scope=project' "$PROJECT_SKILLS/.jig-installation" >/dev/null
grep -Fx 'skills=jig-update=jig-update,github-sync=github-sync' "$PROJECT_SKILLS/.jig-installation" >/dev/null
grep -F 'SKIP ambiguous markerless skill directory:' "$PROJECT_OUTPUT" >/dev/null

# Once provenance exists, canonical title drift is repaired without falling back to name-only ownership.
printf '%s\n' '---' 'name: github-sync' '---' '# Locally Drifted Title' 'drifted content' \
  > "$PROJECT_SKILLS/github-sync/SKILL.md"
JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$PROJECT_SKILLS" --scope project --version "$VERSION" >/dev/null
cmp -s \
  "$PAYLOAD/dist/claude-code-plugin/jig/skills/github-sync/SKILL.md" \
  "$PROJECT_SKILLS/github-sync/SKILL.md"

NEXT_VERSION=v9.9.10
cp -R "$PAYLOAD" "$TEST_ROOT/payload/$NEXT_VERSION"
JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$PROJECT_SKILLS" --scope project --version "$NEXT_VERSION" >/dev/null
grep -Fx 'version=v9.9.10' "$PROJECT_SKILLS/.jig-installation" >/dev/null
grep -Fx 'version=v9.9.9' "$PROJECT_SKILLS/.jig-installation.bak" >/dev/null

USER_SKILLS="$TEST_ROOT/user/.claude/skills"
mkdir -p "$USER_SKILLS/jig-update" "$USER_SKILLS/jig-github-sync"
write_legacy_jig_update "$USER_SKILLS/jig-update/SKILL.md"
printf '%s\n' '---' 'name: jig-github-sync' '---' '# GitHub Sync' 'old prefixed payload' \
  > "$USER_SKILLS/jig-github-sync/SKILL.md"

JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$USER_SKILLS" --scope user --version "$VERSION" >/dev/null

cmp -s \
  "$PAYLOAD/dist/codex/.agents/skills/jig-github-sync/SKILL.md" \
  "$USER_SKILLS/jig-github-sync/SKILL.md"
grep -F 'old prefixed payload' "$USER_SKILLS/jig-github-sync/SKILL.md.bak" >/dev/null
grep -Fx 'scope=user' "$USER_SKILLS/.jig-installation" >/dev/null
grep -Fx 'skills=jig-update=jig-update,github-sync=jig-github-sync' "$USER_SKILLS/.jig-installation" >/dev/null

MALFORMED_SKILLS="$TEST_ROOT/malformed/.claude/skills"
mkdir -p "$TEST_ROOT/malformed/.claude"
cp -R "$PROJECT_SKILLS" "$MALFORMED_SKILLS"
printf '%s\n' 'unexpected=value' >> "$MALFORMED_SKILLS/.jig-installation"
cp "$MALFORMED_SKILLS/github-sync/SKILL.md" "$TEST_ROOT/malformed-before"
if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$MALFORMED_SKILLS" --scope project --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted a malformed installation ledger' >&2
  exit 1
fi
cmp -s "$TEST_ROOT/malformed-before" "$MALFORMED_SKILLS/github-sync/SKILL.md"

CONFLICT_SKILLS="$TEST_ROOT/conflict/.claude/skills"
mkdir -p "$TEST_ROOT/conflict/.claude"
cp -R "$PROJECT_SKILLS" "$CONFLICT_SKILLS"
printf '%s\n' \
  'format=1' \
  'repository=another/repository' \
  'skill=github-sync' \
  'directory=github-sync' \
  > "$CONFLICT_SKILLS/github-sync/.jig-provenance"
cp "$CONFLICT_SKILLS/github-sync/SKILL.md" "$TEST_ROOT/conflict-before"
if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$CONFLICT_SKILLS" --scope project --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted conflicting skill provenance' >&2
  exit 1
fi
cmp -s "$TEST_ROOT/conflict-before" "$CONFLICT_SKILLS/github-sync/SKILL.md"

UNOWNED_SKILLS="$TEST_ROOT/unowned/.claude/skills"
mkdir -p "$UNOWNED_SKILLS/github-sync"
printf '%s\n' 'user-owned content' > "$UNOWNED_SKILLS/github-sync/SKILL.md"

if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$UNOWNED_SKILLS" --scope project --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted an unowned skill root' >&2
  exit 1
fi
grep -F 'user-owned content' "$UNOWNED_SKILLS/github-sync/SKILL.md" >/dev/null

# Every payload is downloaded before the transaction starts.
DOWNLOAD_FAILURE_SKILLS="$TEST_ROOT/download-failure/.claude/skills"
mkdir -p "$DOWNLOAD_FAILURE_SKILLS/jig-update"
write_legacy_jig_update "$DOWNLOAD_FAILURE_SKILLS/jig-update/SKILL.md"
cp "$DOWNLOAD_FAILURE_SKILLS/jig-update/SKILL.md" "$TEST_ROOT/download-failure-before"
rm "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/scripts/new-helper.sh"
if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$DOWNLOAD_FAILURE_SKILLS" --scope project --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted an incomplete download set' >&2
  exit 1
fi
cmp -s "$TEST_ROOT/download-failure-before" "$DOWNLOAD_FAILURE_SKILLS/jig-update/SKILL.md"
[ ! -e "$DOWNLOAD_FAILURE_SKILLS/jig-update/SKILL.md.bak" ]
[ ! -e "$DOWNLOAD_FAILURE_SKILLS/jig-update/.jig-provenance" ]
[ ! -e "$DOWNLOAD_FAILURE_SKILLS/.jig-installation" ]
printf '%s\n' '#!/usr/bin/env sh' 'printf helper' \
  > "$PAYLOAD/dist/claude-code-plugin/jig/skills/jig-update/scripts/new-helper.sh"

# A failure during apply restores both installed files and their previous backups.
ROLLBACK_SKILLS="$TEST_ROOT/rollback/.claude/skills"
mkdir -p "$ROLLBACK_SKILLS/jig-update"
write_legacy_jig_update "$ROLLBACK_SKILLS/jig-update/SKILL.md"
cp "$ROLLBACK_SKILLS/jig-update/SKILL.md" "$TEST_ROOT/rollback-before"
printf '%s\n' 'pre-existing backup' > "$ROLLBACK_SKILLS/jig-update/SKILL.md.bak"
printf '%s\n' 'blocks a later directory creation' > "$ROLLBACK_SKILLS/jig-update/blocked"
ROLLBACK_OUTPUT="$TEST_ROOT/rollback.log"
if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root "$ROLLBACK_SKILLS" --scope project --version "$VERSION" \
  > "$ROLLBACK_OUTPUT" 2>&1; then
  printf '%s\n' 'standalone updater did not fail during forced apply error' >&2
  exit 1
fi
cmp -s "$TEST_ROOT/rollback-before" "$ROLLBACK_SKILLS/jig-update/SKILL.md"
grep -Fx 'pre-existing backup' "$ROLLBACK_SKILLS/jig-update/SKILL.md.bak" >/dev/null
grep -Fx 'blocks a later directory creation' "$ROLLBACK_SKILLS/jig-update/blocked" >/dev/null
[ ! -e "$ROLLBACK_SKILLS/jig-update/scripts" ]
[ ! -e "$ROLLBACK_SKILLS/jig-update/.jig-provenance" ]
[ ! -e "$ROLLBACK_SKILLS/.jig-installation" ]
grep -F 'ROLLBACK restoring standalone installation:' "$ROLLBACK_OUTPUT" >/dev/null

if JIG_UPDATE_RAW_BASE_URL="file://$TEST_ROOT/payload" \
  sh "$SCRIPT" --root .claude/skills --scope project --version "$VERSION" >/dev/null 2>&1; then
  printf '%s\n' 'standalone updater accepted the jig source development mirror' >&2
  exit 1
fi

printf '%s\n' 'claude standalone update tests ok'
