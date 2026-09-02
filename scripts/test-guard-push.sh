#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
GUARD="$ROOT/skills/github-sync/assets/guard-push.sh"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'guard-push tests: %s\n' "$*" >&2
  exit 1
}

# Claude Code and Codex share one payload shape and one answer: exit 2 plus stderr.
exitcode_payload() {
  printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"/workspace"}' "$1"
}

# Antigravity has its own payload shape and answers only through stdout JSON.
decision_payload() {
  printf '{"toolCall":{"name":"run_command","args":{"CommandLine":"%s","Cwd":"/workspace"}},"stepIdx":0,"conversationId":"c"}' "$1"
}

# Runs the guard on the payload in $TEST_ROOT/in; a pipeline would put the exit code
# in a subshell, so the payload goes through a file.
run_guard() {
  set +e
  sh "$GUARD" < "$TEST_ROOT/in" > "$TEST_ROOT/out" 2> "$TEST_ROOT/err"
  code=$?
  set -e
}

expect_exitcode_block() {
  exitcode_payload "$1" > "$TEST_ROOT/in"
  run_guard
  [ "$code" -eq 2 ] || fail "exit-code contract allowed (exit $code): $1"
  grep -q 'jig guard' "$TEST_ROOT/err" || fail "exit-code contract blocked without a reason: $1"
  [ ! -s "$TEST_ROOT/out" ] || fail "exit-code contract wrote to stdout: $1"
}

expect_exitcode_allow() {
  exitcode_payload "$1" > "$TEST_ROOT/in"
  run_guard
  [ "$code" -eq 0 ] || fail "exit-code contract blocked (exit $code): $1"
  [ ! -s "$TEST_ROOT/out" ] || fail "exit-code contract wrote to stdout on allow: $1"
  [ ! -s "$TEST_ROOT/err" ] || fail "exit-code contract wrote to stderr on allow: $1"
}

expect_decision_block() {
  decision_payload "$1" > "$TEST_ROOT/in"
  run_guard
  [ "$code" -eq 0 ] || fail "decision contract exited $code instead of 0: $1"
  grep -Fq '"decision":"deny"' "$TEST_ROOT/out" || fail "decision contract did not deny: $1"
  grep -Fq '"reason":"jig guard' "$TEST_ROOT/out" || fail "decision contract denied without a reason: $1"
  if command -v jq >/dev/null 2>&1; then
    jq -e '.decision == "deny" and (.reason | length) > 0' "$TEST_ROOT/out" >/dev/null || fail "decision contract answer is not valid JSON: $1"
  fi
}

expect_decision_allow() {
  decision_payload "$1" > "$TEST_ROOT/in"
  run_guard
  [ "$code" -eq 0 ] || fail "decision contract exited $code on allow: $1"
  grep -Fq '"decision":"allow"' "$TEST_ROOT/out" || fail "decision contract did not answer allow: $1"
}

for blocked in \
  'git push --force origin main' \
  'git push -f origin develop' \
  'git push --force-with-lease origin main' \
  'git push origin main' \
  'git push origin feature/x:main' \
  'git push origin HEAD:main' \
  'git push origin :main' \
  'git push --delete origin develop' \
  'git push --no-verify origin develop' \
  'cd /repo && git push --no-verify origin develop:main'
do
  expect_exitcode_block "$blocked"
  expect_decision_block "$blocked"
done

for allowed in \
  'git push origin develop:main' \
  'git push origin hotfix/fix-1:main' \
  'git push origin develop' \
  'git push -u origin feature/x' \
  'git push --force origin feature/x' \
  'git status' \
  'echo main' \
  'ls -la'
do
  expect_exitcode_allow "$allowed"
  expect_decision_allow "$allowed"
done

# Unparseable or empty input passes: the git hook and server-side protection back it up.
printf 'not json' > "$TEST_ROOT/in"
run_guard
[ "$code" -eq 0 ] || fail "invalid JSON was blocked"
printf '' > "$TEST_ROOT/in"
run_guard
[ "$code" -eq 0 ] || fail "empty input was blocked"
printf '{"tool_name":"Read","tool_input":{"file_path":"/x"}}' > "$TEST_ROOT/in"
run_guard
[ "$code" -eq 0 ] || fail "a non-shell tool call was blocked"

# Without jq the guard still reads both payload shapes and keeps both answers.
SHIM="$TEST_ROOT/bin"
mkdir -p "$SHIM"
for tool in sh grep cat printf; do
  tool_path=$(command -v "$tool" 2>/dev/null || true)
  [ -n "$tool_path" ] && ln -s "$tool_path" "$SHIM/$tool" 2>/dev/null || true
done
set +e
exitcode_payload 'git push --force origin main' | PATH="$SHIM" sh "$GUARD" >/dev/null 2>&1
code=$?
set -e
[ "$code" -eq 2 ] || fail "without jq the exit-code contract allowed a force push"
set +e
exitcode_payload 'git push origin develop' | PATH="$SHIM" sh "$GUARD" >/dev/null 2>&1
code=$?
set -e
[ "$code" -eq 0 ] || fail "without jq the exit-code contract blocked a develop push"
decision_payload 'git push --force origin main' | PATH="$SHIM" sh "$GUARD" > "$TEST_ROOT/out" 2>/dev/null \
  || fail "without jq the decision contract exited non-zero"
grep -Fq '"decision":"deny"' "$TEST_ROOT/out" || fail "without jq the decision contract did not deny a force push"
decision_payload 'git push origin develop' | PATH="$SHIM" sh "$GUARD" > "$TEST_ROOT/out" 2>/dev/null \
  || fail "without jq the decision contract exited non-zero on allow"
grep -Fq '"decision":"allow"' "$TEST_ROOT/out" || fail "without jq the decision contract did not answer allow"

sh -n "$GUARD"
[ "$(sed -n '2p' "$GUARD")" = "# jig:guard-push v2" ] || fail "guard source lacks the v2 ownership marker on line 2"
echo "guard-push tests ok"
