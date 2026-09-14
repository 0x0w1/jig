# Convert documented GET fields to PUT fields; reject unrecognized policy data.
def keys_only($allowed):
  if type != "object" or ((keys - $allowed) | length) != 0
  then error("unsupported protection fields") else . end;
def bool: if type == "boolean" then . else error("expected boolean") end;
def flag: keys_only(["url", "enabled"]) | .enabled | bool;
def strings: if type == "array" and all(.[]; type == "string") then . else error("expected strings") end;
def actors:
  keys_only(["url","users_url","teams_url","apps_url","users","teams","apps"])
  | with_entries(select(.key == "users" or .key == "teams" or .key == "apps"))
  | with_entries(.value |= (if type == "array" then . else error("expected actors") end))
  | with_entries(.key as $k | .value |= map(if $k == "users" then .login else .slug end))
  | with_entries(.value |= strings);
def checks:
  if . == null then null else
    keys_only(["url","contexts_url","strict","contexts","checks","enforcement_level"])
    | {strict: (.strict | bool), contexts: (.contexts | strings)} +
      (if has("checks") then {checks: (.checks | map(
        keys_only(["context","app_id"]) |
        if (.context | type) != "string" or (.app_id | type) != "number"
        then error("unknown check app binding") else . end))} else {} end)
  end;
def reviews:
  if . == null then null else
    keys_only(["url","dismissal_restrictions","dismiss_stale_reviews","require_code_owner_reviews",
      "required_approving_review_count","require_last_push_approval","bypass_pull_request_allowances"])
    | del(.url)
    | with_entries(
        if .key == "dismissal_restrictions" or .key == "bypass_pull_request_allowances"
        then .value |= actors
        elif .key == "required_approving_review_count"
        then .value |= (if type == "number" and . >= 0 and . <= 6 and floor == . then . else error("invalid review count") end)
        else .value |= bool end)
  end;
keys_only(["url","required_status_checks","enforce_admins","required_pull_request_reviews","restrictions",
  "required_linear_history","allow_force_pushes","allow_deletions","required_conversation_resolution",
  "block_creations","lock_branch","allow_fork_syncing","required_signatures"])
# Required signatures use a separate endpoint. Preserve by declining unsupported updates.
| if has("required_signatures") then error("signature protection requires separate review") else . end
| . as $current
| if (["required_status_checks","enforce_admins","required_pull_request_reviews","restrictions"] - keys | length) > 0
  then error("incomplete current policy") else . end
| {
    required_status_checks: (.required_status_checks | checks),
    enforce_admins: (.enforce_admins | flag),
    required_pull_request_reviews: (.required_pull_request_reviews | reviews),
    restrictions: (if .restrictions == null then null else .restrictions | actors end),
    allow_force_pushes: false,
    allow_deletions: false
  }
  + ($current | with_entries(select(.key == "required_linear_history" or .key == "required_conversation_resolution"
      or .key == "block_creations" or .key == "lock_branch" or .key == "allow_fork_syncing"))
    | with_entries(.value |= flag))
| {action: "update", body: .}
