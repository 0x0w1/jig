#!/usr/bin/env sh
set -eu

# Tests the branch-protection classifier against mocked GitHub API responses. Nothing
# here touches a real repository's settings; the point is to prove that a repository
# already requiring reviews or status checks is never reported as needing jig's
# baseline applied over the top of it.

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
CLASSIFY="$ROOT/skills/github-sync/scripts/classify-protection.sh"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'protection classifier tests: %s\n' "$*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required to run these tests"

run() {
  printf '%s' "$1" | sh "$CLASSIFY"
}

value_of() {
  printf '%s\n' "$1" | awk -F '=' -v k="$2" '$1 == k { sub("^" k "=", ""); print }'
}

expect() {
  actual=$(value_of "$1" "$2")
  [ "$actual" = "$3" ] || fail "$4: expected $2=$3, got '$2=${actual:-<none>}'"
}

# --- Not protected -----------------------------------------------------------------
OUT=$(run '{"message":"Branch not protected","documentation_url":"https://docs.github.com"}')
expect "$OUT" verdict absent "not protected"
expect "$OUT" missing "force_pushes,deletions" "not protected"
expect "$OUT" extras none "not protected"

# --- Exactly jig's baseline --------------------------------------------------------
BASELINE='{
  "required_status_checks": null,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "enforce_admins": {"enabled": false},
  "allow_force_pushes": {"enabled": false},
  "allow_deletions": {"enabled": false},
  "required_conversation_resolution": {"enabled": false}
}'
OUT=$(run "$BASELINE")
expect "$OUT" verdict satisfied "baseline"
expect "$OUT" force_pushes blocked "baseline"
expect "$OUT" deletions blocked "baseline"
expect "$OUT" extras none "baseline"
expect "$OUT" missing none "baseline"

# --- Stronger than jig: reviews and checks required --------------------------------
# This is the case the shipped policy would have wiped out by sending nulls.
STRONGER='{
  "required_status_checks": {"strict": true, "contexts": ["ci"]},
  "required_pull_request_reviews": {"required_approving_review_count": 2},
  "restrictions": null,
  "enforce_admins": {"enabled": true},
  "allow_force_pushes": {"enabled": false},
  "allow_deletions": {"enabled": false},
  "required_conversation_resolution": {"enabled": true}
}'
OUT=$(run "$STRONGER")
expect "$OUT" verdict satisfied "stronger policy"
expect "$OUT" missing none "stronger policy"
case "$(value_of "$OUT" extras)" in
  *pull_request_reviews*) ;;
  *) fail "stronger policy: required reviews were not reported as an extra to preserve" ;;
esac
case "$(value_of "$OUT" extras)" in
  *status_checks*) ;;
  *) fail "stronger policy: required status checks were not reported as an extra to preserve" ;;
esac
case "$(value_of "$OUT" extras)" in
  *enforce_admins*) ;;
  *) fail "stronger policy: enforce_admins was not reported as an extra to preserve" ;;
esac
case "$(value_of "$OUT" extras)" in
  *conversation_resolution*) ;;
  *) fail "stronger policy: conversation resolution was not reported as an extra to preserve" ;;
esac

# --- Stronger in review terms but still allowing force pushes ----------------------
# jig has something to add here, and must add only that without dropping the reviews.
MIXED='{
  "required_status_checks": null,
  "required_pull_request_reviews": {"required_approving_review_count": 1},
  "restrictions": null,
  "enforce_admins": {"enabled": false},
  "allow_force_pushes": {"enabled": true},
  "allow_deletions": {"enabled": false}
}'
OUT=$(run "$MIXED")
expect "$OUT" verdict needs-tightening "mixed policy"
expect "$OUT" force_pushes allowed "mixed policy"
expect "$OUT" deletions blocked "mixed policy"
expect "$OUT" missing force_pushes "mixed policy"
case "$(value_of "$OUT" extras)" in
  *pull_request_reviews*) ;;
  *) fail "mixed policy: required reviews must still be reported as an extra to preserve" ;;
esac

# --- Protected but both guarantees missing -----------------------------------------
LOOSE='{
  "required_status_checks": null,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "enforce_admins": {"enabled": false},
  "allow_force_pushes": {"enabled": true},
  "allow_deletions": {"enabled": true}
}'
OUT=$(run "$LOOSE")
expect "$OUT" verdict needs-tightening "loose policy"
expect "$OUT" missing "force_pushes,deletions" "loose policy"
expect "$OUT" extras none "loose policy"

# --- Restrictions are an extra jig must keep ---------------------------------------
RESTRICTED='{
  "required_status_checks": null,
  "required_pull_request_reviews": null,
  "restrictions": {"users": [], "teams": ["release"]},
  "enforce_admins": {"enabled": false},
  "allow_force_pushes": {"enabled": false},
  "allow_deletions": {"enabled": false}
}'
OUT=$(run "$RESTRICTED")
expect "$OUT" verdict satisfied "restrictions"
case "$(value_of "$OUT" extras)" in
  *restrictions*) ;;
  *) fail "restrictions: push restrictions were not reported as an extra to preserve" ;;
esac

# --- A field the response omits is unknown, never assumed safe ---------------------
PARTIAL='{"required_pull_request_reviews": {"required_approving_review_count": 1}}'
OUT=$(run "$PARTIAL")
expect "$OUT" force_pushes unknown "partial response"
expect "$OUT" deletions unknown "partial response"
expect "$OUT" verdict unreadable "partial response"

# --- Unreadable input ---------------------------------------------------------------
OUT=$(run 'not json at all')
expect "$OUT" verdict unreadable "invalid json"
OUT=$(run '[]')
expect "$OUT" verdict unreadable "json array"
OUT=$(printf '' | sh "$CLASSIFY")
expect "$OUT" verdict unreadable "empty input"

# --- API errors and incomplete flags are not permission to create protection --------
for payload in '{}' '{"message":"Bad credentials"}' '{"message":"Not Found"}' '{"message":"API rate limit exceeded"}' '{"allow_force_pushes":{"enabled":null},"allow_deletions":{"enabled":false}}'; do
  OUT=$(run "$payload")
  expect "$OUT" verdict unreadable "ambiguous/error API response"
done

# --- --file input matches stdin input -----------------------------------------------
printf '%s' "$STRONGER" > "$TEST_ROOT/protection.json"
FILE_OUT=$(sh "$CLASSIFY" --file "$TEST_ROOT/protection.json")
[ "$FILE_OUT" = "$(run "$STRONGER")" ] || fail "--file and stdin disagree"
if sh "$CLASSIFY" --file "$TEST_ROOT/missing.json" >/dev/null 2>&1; then
  OUT=$(sh "$CLASSIFY" --file "$TEST_ROOT/missing.json")
  expect "$OUT" verdict unreadable "missing file"
fi
if sh "$CLASSIFY" --bogus >/dev/null 2>&1; then
  fail "an unknown option was accepted"
fi

# --- Request planning verifies the body, not just the classifier labels -------------
PLAN="$ROOT/skills/github-sync/scripts/plan-protection.sh"
plan() { printf '%s' "$1" | sh "$PLAN"; }
[ "$(plan "$STRONGER" | jq -r .action)" = none ] || fail "strong policy must produce no update"
[ "$(plan '{"message":"Bad credentials"}' | jq -r .action)" = blocked ] || fail "API errors must block"
plan '{"message":"Branch not protected"}' | jq -e '.action == "update" and (.body | has("required_status_checks") and has("restrictions"))' >/dev/null || fail "new protection requires a valid PUT body"

COMPLEX=$(printf '%s' "$STRONGER" | jq '.allow_force_pushes.enabled = true |
 .required_status_checks = {strict:true, contexts:["ci"], checks:[{context:"ci",app_id:42}]} |
 .required_pull_request_reviews += {dismiss_stale_reviews:true,require_code_owner_reviews:true,require_last_push_approval:true,
 dismissal_restrictions:{users:[{login:"reviewer"}],teams:[{slug:"reviewers"}],apps:[{slug:"review-app"}]},
 bypass_pull_request_allowances:{users:[],teams:[{slug:"maintainers"}],apps:[]}} |
 .restrictions = {users:[{login:"maintainer"}],teams:[{slug:"release"}],apps:[{slug:"release-app"}]} |
 .required_linear_history = {enabled:true} | .block_creations = {enabled:true} |
 .lock_branch = {enabled:true} | .allow_fork_syncing = {enabled:false}')
BODY=$(plan "$COMPLEX")
printf '%s' "$BODY" | jq -e '.action == "update" and (.body |
 .allow_force_pushes == false and .allow_deletions == false and .enforce_admins == true and
 .required_status_checks == {strict:true,contexts:["ci"],checks:[{context:"ci",app_id:42}]} and
 .required_pull_request_reviews == {required_approving_review_count:2,dismiss_stale_reviews:true,require_code_owner_reviews:true,require_last_push_approval:true,
 dismissal_restrictions:{users:["reviewer"],teams:["reviewers"],apps:["review-app"]},
 bypass_pull_request_allowances:{users:[],teams:["maintainers"],apps:[]}} and
 .restrictions == {users:["maintainer"],teams:["release"],apps:["release-app"]} and
 .required_conversation_resolution == true and .required_linear_history == true and .block_creations == true and
 .lock_branch == true and .allow_fork_syncing == false)' >/dev/null || fail "existing policy was lost or mistranslated in PUT body"
# Simulate server readback; a second identical sync must be a no-op.
AFTER=$(printf '%s' "$COMPLEX" | jq '.allow_force_pushes.enabled=false')
[ "$(plan "$AFTER" | jq -r .action)" = none ] || fail "repeated sync must not write"
for expr in '.new_policy={enabled:true}' '.required_signatures={enabled:true}' 'del(.restrictions)' '.required_status_checks.checks[0].app_id=null'; do
  UNKNOWN=$(printf '%s' "$COMPLEX" | jq "$expr")
  plan "$UNKNOWN" | jq -e '.action == "blocked" and (has("body") | not)' >/dev/null || fail "unsupported response must not yield an update"
done

sh -n "$CLASSIFY"
echo "protection classifier tests ok"
