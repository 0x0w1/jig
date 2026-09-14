#!/usr/bin/env sh
set -eu
# Pure local planner: consumes a saved GET response; never invokes gh or writes Git config.
# Output: {action: none|update|blocked, body?: <PUT payload>, reason?: <text>}.
# Classification does not grant authorization to send an update.
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
cat > "$WORK/current.json"
classification=$(sh "$SCRIPT_DIR/classify-protection.sh" --file "$WORK/current.json")
verdict=$(printf '%s\n' "$classification" | sed -n 's/^verdict=//p')
case "$verdict" in
  satisfied) printf '{"action":"none"}\n' ;;
  absent)
    printf '%s\n' '{"action":"update","body":{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}}' ;;
  needs-tightening)
    # GET objects are not PUT objects. Only a known lossless conversion is supported.
    if jq -e -f "$SCRIPT_DIR/protection-request.jq" "$WORK/current.json" > "$WORK/plan.json" 2> "$WORK/error"; then
      cat "$WORK/plan.json"
    else
      printf '{"action":"blocked","reason":"unsupported or incomplete protection fields; preserve policy and report for manual review"}\n'
    fi ;;
  *) printf '{"action":"blocked","reason":"unreadable protection response"}\n' ;;
esac
