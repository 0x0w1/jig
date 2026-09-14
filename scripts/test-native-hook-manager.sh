#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
MANAGER="$ROOT/skills/github-sync/scripts/manage-native-hooks.sh"
GUARD_SOURCE="$ROOT/skills/github-sync/assets/guard-push.sh"
GUARD_COMMAND='sh -c '\''guard=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)/jig/guard-push.sh; [ -f "$guard" ] || exit 0; exec sh "$guard"'\'''
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'native hook manager tests: %s\n' "$*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required to run these tests"

# Every run uses an empty Codex home so the machine's own plugin state never decides
# whether the tests see Codex as installed.
CODEX_HOME="$TEST_ROOT/codex-home"
export CODEX_HOME
mkdir -p "$CODEX_HOME"

# A managed project carries the rules-file stamp for each installed host. The guard
# payload comes from the manager's own sibling asset, not from the project.
new_project() {
  project="$1"
  shift
  rm -rf "$project"
  mkdir -p "$project"
  git -C "$project" init -q
  for host in "$@"; do
    case "$host" in
      codex) printf '# Rules\n\n<!-- jig:start github-release-setup -->\n<!-- jig:version v0.0.0 -->\n<!-- jig:end github-release-setup -->\n' > "$project/AGENTS.md" ;;
      antigravity) printf '# Rules\n\n<!-- jig:start github-release-setup -->\n<!-- jig:version v0.0.0 -->\n<!-- jig:end github-release-setup -->\n' > "$project/GEMINI.md" ;;
    esac
  done
}

manager() {
  (cd "$1" && shift && sh "$MANAGER" "$@")
}

status_of() {
  manager "$1" status --host "$2" | sed "s/^$2: //"
}

guard_path() {
  printf '%s/.git/jig/guard-push.sh' "$1"
}

# Fresh project with both hosts: install creates both files from the templates and
# copies the guard clone-local.
PROJECT="$TEST_ROOT/fresh"
new_project "$PROJECT" codex antigravity
[ "$(status_of "$PROJECT" codex)" = "not installed" ] || fail "fresh codex status was not 'not installed'"
[ "$(status_of "$PROJECT" antigravity)" = "not installed" ] || fail "fresh antigravity status was not 'not installed'"
manager "$PROJECT" install
[ -f "$PROJECT/.codex/hooks.json" ] || fail "install did not create .codex/hooks.json"
[ -f "$PROJECT/.agents/hooks.json" ] || fail "install did not create .agents/hooks.json"
GUARD=$(guard_path "$PROJECT")
[ -f "$GUARD" ] || fail "install did not copy the guard clone-local"
[ -x "$GUARD" ] || fail "the clone-local guard is not executable"
cmp -s "$GUARD_SOURCE" "$GUARD" || fail "the clone-local guard differs from the shipped source"
jq -e --arg cmd "$GUARD_COMMAND" '.hooks.PreToolUse[0].matcher == "Bash" and .hooks.PreToolUse[0].hooks[0].command == $cmd and .hooks.PreToolUse[0].hooks[0].statusMessage == "jig guard-push"' \
  "$PROJECT/.codex/hooks.json" >/dev/null || fail "codex template does not carry the jig entry"
jq -e --arg cmd "$GUARD_COMMAND" '.["jig-guard-push"].PreToolUse[0].matcher == "run_command" and .["jig-guard-push"].PreToolUse[0].hooks[0].command == $cmd' \
  "$PROJECT/.agents/hooks.json" >/dev/null || fail "antigravity template does not carry the jig entry"
[ "$(status_of "$PROJECT" codex)" = "installed" ] || fail "codex status after install was not 'installed'"
[ "$(status_of "$PROJECT" antigravity)" = "installed" ] || fail "antigravity status after install was not 'installed'"

# The installed entry command runs the guard from anywhere inside the worktree.
mkdir -p "$PROJECT/nested/deeper"
(
  cd "$PROJECT/nested/deeper"
  command_line=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$PROJECT/.codex/hooks.json")
  if printf '{"tool_input":{"command":"git push --force origin main"}}' | sh -c "$command_line" 2>/dev/null; then
    exit 1
  fi
  printf '{"toolCall":{"args":{"CommandLine":"git push origin main"}}}' | sh -c "$command_line" | grep -Fq '"decision":"deny"'
) || fail "the installed hook command did not run the guard from a subdirectory"

# With the guard absent the entry passes rather than erroring: the git hook and
# server-side protection are the backstops.
mv "$GUARD" "$TEST_ROOT/guard-parked"
(
  cd "$PROJECT"
  command_line=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$PROJECT/.codex/hooks.json")
  printf '{"tool_input":{"command":"git push --force origin main"}}' | sh -c "$command_line"
) || fail "the hook entry failed instead of passing when the guard was missing"
[ "$(status_of "$PROJECT" codex)" = "guard missing" ] || fail "a missing clone-local guard was not reported"
mv "$TEST_ROOT/guard-parked" "$GUARD"
printf '#!/bin/sh\n# jig:guard-push v0\nexit 0\n' > "$GUARD"
[ "$(status_of "$PROJECT" codex)" = "guard drift" ] || fail "a drifted clone-local guard was not reported"
manager "$PROJECT" install
cmp -s "$GUARD_SOURCE" "$GUARD" || fail "install did not repair the drifted guard"
[ "$(status_of "$PROJECT" codex)" = "installed" ] || fail "codex status after guard repair was not 'installed'"

# Re-running is idempotent and leaves the files byte-identical.
cp "$PROJECT/.codex/hooks.json" "$TEST_ROOT/codex-before"
cp "$PROJECT/.agents/hooks.json" "$TEST_ROOT/antigravity-before"
manager "$PROJECT" install
cmp -s "$TEST_ROOT/codex-before" "$PROJECT/.codex/hooks.json" || fail "a second install rewrote .codex/hooks.json"
cmp -s "$TEST_ROOT/antigravity-before" "$PROJECT/.agents/hooks.json" || fail "a second install rewrote .agents/hooks.json"

# Uninstalling one host keeps the guard while the other host still points at it.
manager "$PROJECT" uninstall --host codex
[ ! -e "$PROJECT/.codex/hooks.json" ] || fail "uninstall left .codex/hooks.json behind"
[ ! -e "$PROJECT/.codex" ] || fail "uninstall left an empty .codex directory behind"
[ -f "$GUARD" ] || fail "uninstalling one host removed the guard the other host still uses"
manager "$PROJECT" uninstall
[ ! -e "$PROJECT/.agents/hooks.json" ] || fail "uninstall left .agents/hooks.json behind"
[ ! -e "$GUARD" ] || fail "the final uninstall left the clone-local guard behind"

# Existing user hooks are preserved through install and uninstall.
PROJECT="$TEST_ROOT/merge"
new_project "$PROJECT" codex antigravity
mkdir -p "$PROJECT/.codex" "$PROJECT/.agents"
cat > "$PROJECT/.codex/hooks.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "./scripts/user-check.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "./scripts/user-lint.sh" } ] }
    ]
  },
  "userSetting": true
}
EOF
cat > "$PROJECT/.agents/hooks.json" <<'EOF'
{
  "my-linter": {
    "PostToolUse": [
      { "matcher": "run_command", "hooks": [ { "type": "command", "command": "./scripts/lint.sh", "timeout": 10 } ] }
    ]
  }
}
EOF
manager "$PROJECT" install
jq -e '.userSetting == true and (.hooks.PostToolUse | length) == 1 and (.hooks.PreToolUse | length) == 2 and .hooks.PreToolUse[0].hooks[0].command == "./scripts/user-check.sh"' \
  "$PROJECT/.codex/hooks.json" >/dev/null || fail "codex merge lost a user entry"
jq -e 'has("my-linter") and has("jig-guard-push") and .["my-linter"].PostToolUse[0].hooks[0].timeout == 10' \
  "$PROJECT/.agents/hooks.json" >/dev/null || fail "antigravity merge lost a user group"
[ "$(status_of "$PROJECT" codex)" = "installed" ] || fail "codex status after merge was not 'installed'"
manager "$PROJECT" uninstall
[ -f "$PROJECT/.codex/hooks.json" ] || fail "uninstall removed a file that still held user hooks"
jq -e '.userSetting == true and (.hooks.PreToolUse | length) == 1 and (.hooks.PostToolUse | length) == 1 and ([.. | strings | select(contains("guard-push"))] | length) == 0' \
  "$PROJECT/.codex/hooks.json" >/dev/null || fail "codex uninstall did not leave exactly the user entries"
jq -e 'has("my-linter") and (has("jig-guard-push") | not)' "$PROJECT/.agents/hooks.json" >/dev/null || fail "antigravity uninstall did not leave exactly the user group"
[ ! -e "$(guard_path "$PROJECT")" ] || fail "uninstall left the guard behind with no jig entry remaining"

# An outdated jig entry is repaired in place.
PROJECT="$TEST_ROOT/drift"
new_project "$PROJECT" codex antigravity
mkdir -p "$PROJECT/.codex" "$PROJECT/.agents"
cat > "$PROJECT/.codex/hooks.json" <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"sh /old/path/guard-push.sh","statusMessage":"jig guard-push"}]}]}}
EOF
cat > "$PROJECT/.agents/hooks.json" <<'EOF'
{"jig-guard-push":{"enabled":false,"PreToolUse":[{"matcher":"run_command","hooks":[{"command":"sh /old/path/guard-push.sh"}]}]}}
EOF
[ "$(status_of "$PROJECT" codex)" = "entry drift" ] || fail "codex drift was not reported"
[ "$(status_of "$PROJECT" antigravity)" = "entry drift" ] || fail "antigravity drift was not reported"
manager "$PROJECT" install
[ "$(status_of "$PROJECT" codex)" = "installed" ] || fail "codex drift was not repaired"
[ "$(status_of "$PROJECT" antigravity)" = "installed" ] || fail "antigravity drift was not repaired"
jq -e '(.hooks.PreToolUse | length) == 1' "$PROJECT/.codex/hooks.json" >/dev/null || fail "codex repair duplicated the entry"

# A user's own entry that already points at the guard is reported and left alone.
PROJECT="$TEST_ROOT/user-entry"
new_project "$PROJECT" codex
mkdir -p "$PROJECT/.codex"
cat > "$PROJECT/.codex/hooks.json" <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"sh .git/jig/guard-push.sh"}]}]}}
EOF
cp "$PROJECT/.codex/hooks.json" "$TEST_ROOT/user-entry-before"
[ "$(status_of "$PROJECT" codex)" = "user entry" ] || fail "a user entry pointing at the guard was not reported"
manager "$PROJECT" install
cmp -s "$TEST_ROOT/user-entry-before" "$PROJECT/.codex/hooks.json" || fail "install changed a user entry"
manager "$PROJECT" uninstall
cmp -s "$TEST_ROOT/user-entry-before" "$PROJECT/.codex/hooks.json" || fail "uninstall changed a user entry"

# Only detected hosts get a file; an entry left behind after the host is gone is a leftover.
PROJECT="$TEST_ROOT/codex-only"
new_project "$PROJECT" codex
manager "$PROJECT" install
[ -f "$PROJECT/.codex/hooks.json" ] || fail "codex-only install did not create .codex/hooks.json"
[ ! -e "$PROJECT/.agents/hooks.json" ] || fail "codex-only install created .agents/hooks.json"
[ "$(status_of "$PROJECT" antigravity)" = "host not detected" ] || fail "undetected antigravity was not reported as such"
rm "$PROJECT/AGENTS.md"
[ "$(status_of "$PROJECT" codex)" = "leftover" ] || fail "a jig entry without its host was not reported as leftover"
manager "$PROJECT" uninstall
[ ! -e "$PROJECT/.codex/hooks.json" ] || fail "uninstall did not clear the leftover"

# Codex installed as a plugin has no rules-file stamp; the Codex config is the evidence.
PROJECT="$TEST_ROOT/codex-plugin"
new_project "$PROJECT"
[ "$(status_of "$PROJECT" codex)" = "host not detected" ] || fail "codex was detected without plugin or stamp evidence"
printf '[plugins."jig@jig"]\nenabled = true\n' > "$CODEX_HOME/config.toml"
[ "$(status_of "$PROJECT" codex)" = "not installed" ] || fail "a plugin-installed Codex was not detected"
manager "$PROJECT" install --host codex
[ -f "$PROJECT/.codex/hooks.json" ] || fail "plugin-installed Codex did not get a hook entry"
[ "$(status_of "$PROJECT" codex)" = "installed" ] || fail "plugin-installed Codex status was not 'installed'"
manager "$PROJECT" uninstall --host codex
rm -f "$CODEX_HOME/config.toml"

# Invalid JSON and symlinks are refused without changes.
PROJECT="$TEST_ROOT/invalid"
new_project "$PROJECT" codex antigravity
mkdir -p "$PROJECT/.codex" "$PROJECT/.agents"
printf '{ not json' > "$PROJECT/.codex/hooks.json"
printf '[]' > "$PROJECT/.agents/hooks.json"
[ "$(status_of "$PROJECT" codex)" = "invalid json" ] || fail "invalid JSON was not reported for codex"
[ "$(status_of "$PROJECT" antigravity)" = "invalid json" ] || fail "a non-object document was not reported for antigravity"
if manager "$PROJECT" install --host codex 2>/dev/null; then
  fail "install accepted invalid JSON"
fi
[ "$(cat "$PROJECT/.codex/hooks.json")" = "{ not json" ] || fail "blocked install changed the invalid file"
if manager "$PROJECT" uninstall --host codex 2>/dev/null; then
  fail "uninstall accepted invalid JSON"
fi

PROJECT="$TEST_ROOT/symlink"
new_project "$PROJECT" codex
mkdir -p "$PROJECT/.codex"
ln -s /dev/null "$PROJECT/.codex/hooks.json"
[ "$(status_of "$PROJECT" codex)" = "symlink" ] || fail "a symlink hook file was not reported"
if manager "$PROJECT" install --host codex 2>/dev/null; then
  fail "install accepted a symlink hook file"
fi
[ -L "$PROJECT/.codex/hooks.json" ] || fail "blocked install replaced the symlink"

# Without jq: a fresh file is still written from the template; an existing file is never touched.
SHIM="$TEST_ROOT/bin"
mkdir -p "$SHIM"
for tool in sh git grep cat mv cp rm rmdir mkdir mktemp dirname sed chmod cmp printf; do
  tool_path=$(command -v "$tool" 2>/dev/null || true)
  [ -n "$tool_path" ] && ln -s "$tool_path" "$SHIM/$tool" 2>/dev/null || true
done
PROJECT="$TEST_ROOT/no-jq"
new_project "$PROJECT" codex antigravity
(cd "$PROJECT" && PATH="$SHIM" sh "$MANAGER" install --host codex) || fail "without jq install could not write a fresh file"
jq -e --arg cmd "$GUARD_COMMAND" '.hooks.PreToolUse[0].hooks[0].command == $cmd and .hooks.PreToolUse[0].hooks[0].statusMessage == "jig guard-push"' \
  "$PROJECT/.codex/hooks.json" >/dev/null || fail "template written without jq is not the jig entry"
mkdir -p "$PROJECT/.agents"
printf '{"my-linter":{}}' > "$PROJECT/.agents/hooks.json"
if (cd "$PROJECT" && PATH="$SHIM" sh "$MANAGER" install --host antigravity 2>/dev/null); then
  fail "without jq install merged into an existing file"
fi
[ "$(cat "$PROJECT/.agents/hooks.json")" = '{"my-linter":{}}' ] || fail "blocked no-jq install changed the file"
[ "$(cd "$PROJECT" && PATH="$SHIM" sh "$MANAGER" status --host antigravity)" = "antigravity: jq missing" ] || fail "status without jq did not say so"

# Usage errors.
if manager "$TEST_ROOT/fresh" frobnicate 2>/dev/null; then
  fail "an unknown mode was accepted"
fi
if manager "$TEST_ROOT/fresh" install --host gemini 2>/dev/null; then
  fail "an unknown host was accepted"
fi

sh -n "$MANAGER"
echo "native hook manager tests ok"
