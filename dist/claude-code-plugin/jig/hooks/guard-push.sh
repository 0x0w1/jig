#!/bin/sh
# jig:guard-push v1
# Claude Code PreToolUse hook (matcher: Bash). Blocks git push commands that
# violate the jig branch model before they run, including --no-verify
# attempts that would bypass the git pre-push guard. Uncertain input passes
# (fail-open): the git hook and server-side protection are the backstops.
# Exit 2 blocks the tool call; stderr is shown to the model.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -n "$cmd" ] || exit 0
else
  cmd=$input
fi

case "$cmd" in
  *git*push*) ;;
  *) exit 0 ;;
esac

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

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

exit 0
