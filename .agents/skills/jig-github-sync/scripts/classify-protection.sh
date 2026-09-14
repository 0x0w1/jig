#!/usr/bin/env sh
set -eu

# Reads one branch-protection response from the GitHub API and reports what it already
# guarantees, so github-sync can add what is missing instead of replacing the policy.
#
# jig guarantees exactly two things on main and develop: no force pushes and no branch
# deletion. It deliberately requires neither pull-request reviews nor status checks, but
# "does not add" is not "removes" — a repository that already requires reviews keeps
# requiring them. Everything this script lists under extras= is owned by the repository,
# not by jig, and must survive a sync.
#
# Usage:
#   sh classify-protection.sh --file <saved-response.json>  # retain HTTP status separately
#   sh classify-protection.sh --file <path>
#
# Output, one key=value per line:
#   verdict=absent|satisfied|needs-tightening|unreadable
#   force_pushes=blocked|allowed|unknown
#   deletions=blocked|allowed|unknown
#   extras=none|<comma-separated protections jig does not own>
#   missing=none|<comma-separated jig guarantees not yet in place>
#
# Exit codes: 0 classified, 2 usage or environment error.

usage() {
  cat >&2 <<'EOF'
Usage: classify-protection.sh [--file <path>]

Reads a GitHub branch-protection JSON response from stdin, or from --file.
A 404 body ("Branch not protected") is reported as verdict=absent.
EOF
  exit 2
}

INPUT_FILE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)
      shift; [ "$#" -gt 0 ] || usage
      INPUT_FILE="$1"
      ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done

emit_unreadable() {
  printf 'verdict=unreadable\n'
  printf 'force_pushes=unknown\n'
  printf 'deletions=unknown\n'
  printf 'extras=none\n'
  printf 'missing=none\n'
  printf 'reason=%s\n' "$1"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_unreadable "jq is not available"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
PAYLOAD="$WORK/payload.json"

if [ -n "$INPUT_FILE" ]; then
  [ -f "$INPUT_FILE" ] || emit_unreadable "input file not found: $INPUT_FILE"
  cat "$INPUT_FILE" > "$PAYLOAD"
else
  cat > "$PAYLOAD"
fi

[ -s "$PAYLOAD" ] && jq -e -s 'length == 1 and (.[0] | type == "object")' "$PAYLOAD" >/dev/null 2>&1 \
  || emit_unreadable "the response is not a JSON object"

# Only the specific unprotected-branch response is absence. Authentication,
# rate-limit, generic 404, and malformed responses are never setup candidates.
if jq -e '.message == "Branch not protected" and ((.status // "404" | tostring) == "404") and ((keys - ["message","documentation_url","status"]) | length == 0)' "$PAYLOAD" >/dev/null 2>&1; then
  printf 'verdict=absent\nforce_pushes=allowed\ndeletions=allowed\nextras=none\nmissing=force_pushes,deletions\n'
  exit 0
fi
jq -e 'has("message") | not' "$PAYLOAD" >/dev/null 2>&1 || emit_unreadable "API error response"
jq -e 'all(.allow_force_pushes, .allow_deletions; type == "object" and (.enabled | type == "boolean"))' "$PAYLOAD" >/dev/null 2>&1 \
  || emit_unreadable "missing or non-boolean protection flags"

# An "enabled" flag jig can read, or unknown when the field is missing entirely.
flag_state() {
  jq -r --arg key "$1" '
    if has($key) | not then "unknown"
    elif (.[$key] | type) == "object" and (.[$key] | has("enabled")) then (if .[$key].enabled then "on" else "off" end)
    elif (.[$key] | type) == "boolean" then (if .[$key] then "on" else "off" end)
    else "unknown" end
  ' "$PAYLOAD"
}

force_state=$(flag_state allow_force_pushes)
deletion_state=$(flag_state allow_deletions)

case "$force_state" in
  on) force_pushes=allowed ;;
  off) force_pushes=blocked ;;
  *) force_pushes=unknown ;;
esac
case "$deletion_state" in
  on) deletions=allowed ;;
  off) deletions=blocked ;;
  *) deletions=unknown ;;
esac

# Protections the repository added on its own. jig never sends a body that drops one.
extras=$(jq -r '
  [
    (if (.required_pull_request_reviews // null) != null then "pull_request_reviews" else empty end),
    (if (.required_status_checks // null) != null then "status_checks" else empty end),
    (if (.restrictions // null) != null then "restrictions" else empty end),
    (if (.enforce_admins.enabled // false) then "enforce_admins" else empty end),
    (if (.required_conversation_resolution.enabled // false) then "conversation_resolution" else empty end),
    (if (.required_linear_history.enabled // false) then "linear_history" else empty end),
    (if (.required_signatures.enabled // false) then "signatures" else empty end),
    (if (.block_creations.enabled // false) then "block_creations" else empty end),
    (if (.lock_branch.enabled // false) then "lock_branch" else empty end)
  ] | if length == 0 then "none" else join(",") end
' "$PAYLOAD")

missing=""
[ "$force_pushes" = blocked ] || missing="force_pushes"
if [ "$deletions" != blocked ]; then
  if [ -n "$missing" ]; then missing="$missing,deletions"; else missing="deletions"; fi
fi

if [ -z "$missing" ]; then
  verdict=satisfied
  missing=none
else
  verdict=needs-tightening
fi

printf 'verdict=%s\n' "$verdict"
printf 'force_pushes=%s\n' "$force_pushes"
printf 'deletions=%s\n' "$deletions"
printf 'extras=%s\n' "$extras"
printf 'missing=%s\n' "$missing"
