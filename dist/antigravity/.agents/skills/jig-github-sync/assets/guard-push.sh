#!/bin/sh
# jig:guard-push v2
# PreToolUse push guard shared by every jig host. Blocks git push commands that
# violate the jig branch model before they run, including --no-verify attempts
# that would bypass the git pre-push guard. Uncertain input passes (fail-open):
# the git hook and server-side protection are the backstops.
#
# Claude Code (plugin hooks/hooks.json) and Codex (.codex/hooks.json) send
# {"tool_input":{"command":...}} and read exit 2 plus stderr as a block.
# Antigravity (.agents/hooks.json) sends {"toolCall":{"args":{"CommandLine":...}}}
# and reads only a stdout {"decision":"deny","reason":...}; a non-zero exit is
# treated as allow there, so that branch always exits 0 and speaks JSON.

input=$(cat)

contract=exitcode
if command -v jq >/dev/null 2>&1; then
  if printf '%s' "$input" | jq -e 'has("toolCall")' >/dev/null 2>&1; then
    contract=decision
  fi
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // .toolCall.args.CommandLine // empty' 2>/dev/null)
else
  case "$input" in
    *'"toolCall"'*) contract=decision ;;
  esac
  cmd=$input
fi

allow() {
  if [ "$contract" = decision ]; then
    printf '{"decision":"allow"}\n'
  fi
  exit 0
}

# Reasons must stay free of double quotes and backslashes: they are embedded in
# the Antigravity JSON answer verbatim.
deny() {
  if [ "$contract" = decision ]; then
    printf '{"decision":"deny","reason":"%s"}\n' "$1"
    exit 0
  fi
  printf '%s\n' "$1" >&2
  exit 2
}

[ -n "$cmd" ] || allow

case "$cmd" in
  *git*push*) ;;
  *) allow ;;
esac

touches_protected() {
  printf '%s' "$cmd" | grep -qE '(^|[^A-Za-z0-9_/-])(main|develop)([^A-Za-z0-9_/-]|$)'
}

if printf '%s' "$cmd" | grep -qE '(--force([^-]|$)|--force-with-lease|(^|[[:space:]])-f([[:space:]]|$))' && touches_protected; then
  deny "jig guard: force push touching main/develop is blocked. Never force push a protected branch."
fi

if printf '%s' "$cmd" | grep -qE '([[:space:]]:(main|develop)([[:space:]]|$)|--delete[[:space:]].*(main|develop))'; then
  deny "jig guard: deleting a protected branch is blocked."
fi

if printf '%s' "$cmd" | grep -qE '(^|[[:space:]:])main([[:space:]]|$)' \
  && ! printf '%s' "$cmd" | grep -qE '(develop|hotfix/[A-Za-z0-9._-]+):main'; then
  deny "jig guard: direct push to main is blocked. Release with: git push origin develop:main, or hotfix-flow with: git push origin hotfix/<slug>:main"
fi

if printf '%s' "$cmd" | grep -qE '(--no-verify)' && touches_protected; then
  deny "jig guard: --no-verify on a protected-branch push is blocked. The pre-push guard must run."
fi

allow
