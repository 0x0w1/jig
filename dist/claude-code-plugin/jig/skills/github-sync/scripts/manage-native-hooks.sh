#!/usr/bin/env sh
set -eu

# Installs the jig push guard as a native PreToolUse hook for the CLIs that have no
# plugin system. Codex reads .codex/hooks.json and Antigravity reads .agents/hooks.json
# in the workspace; both files may hold the user's own hooks, so this manager touches
# only the entry it owns and never rewrites anything else. The guard itself is the
# github-sync payload file assets/guard-push.sh, which jig-update refreshes; the hook
# entry carries only its path so a payload update never changes the entry Codex asked
# the user to trust.

usage() {
  cat >&2 <<'EOF'
Usage: manage-native-hooks.sh install   [--host codex|antigravity]
       manage-native-hooks.sh uninstall [--host codex|antigravity]
       manage-native-hooks.sh status    [--host codex|antigravity]
EOF
  exit 2
}

fail() {
  printf 'jig native hook manager: %s\n' "$*" >&2
  exit 1
}

say() {
  printf 'jig native hook manager: %s\n' "$*"
}

GUARD_RELATIVE=".agents/skills/jig-github-sync/assets/guard-push.sh"
GUARD_COMMAND='sh "$(git rev-parse --show-toplevel)/.agents/skills/jig-github-sync/assets/guard-push.sh"'
GUARD_PATH_FRAGMENT="jig-github-sync/assets/guard-push.sh"
CODEX_MARKER="jig guard-push"
ANTIGRAVITY_KEY="jig-guard-push"
MANAGED_BLOCK_START="<!-- jig:start github-release-setup -->"

[ "$#" -ge 1 ] || usage
MODE="$1"
shift

HOSTS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      shift
      [ "$#" -gt 0 ] || usage
      case "$1" in
        codex|antigravity) HOSTS="$HOSTS $1" ;;
        *) usage ;;
      esac
      ;;
    *) usage ;;
  esac
  shift
done
[ -n "$HOSTS" ] || HOSTS="codex antigravity"

case "$MODE" in
  install|uninstall|status) ;;
  *) usage ;;
esac

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "the current directory is not inside a Git worktree"
ROOT=$(git rev-parse --show-toplevel)
GUARD_FILE="$ROOT/$GUARD_RELATIVE"

have_jq() {
  command -v jq >/dev/null 2>&1
}

rules_file() {
  case "$1" in
    codex) printf '%s' "$ROOT/AGENTS.md" ;;
    antigravity) printf '%s' "$ROOT/GEMINI.md" ;;
  esac
}

hooks_file() {
  case "$1" in
    codex) printf '%s' "$ROOT/.codex/hooks.json" ;;
    antigravity) printf '%s' "$ROOT/.agents/hooks.json" ;;
  esac
}

host_detected() {
  detected_rules=$(rules_file "$1")
  [ -f "$detected_rules" ] && grep -Fq "$MANAGED_BLOCK_START" "$detected_rules"
}

# The templates below are what a fresh file looks like. They are also the shape the
# merge produces, so a file jig created alone and a file jig merged into read the same.
write_template() {
  template_host="$1"
  template_destination="$2"
  case "$template_host" in
    codex)
      cat <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "sh \"$(git rev-parse --show-toplevel)/.agents/skills/jig-github-sync/assets/guard-push.sh\"",
            "statusMessage": "jig guard-push"
          }
        ]
      }
    ]
  }
}
EOF
      ;;
    antigravity)
      cat <<'EOF'
{
  "jig-guard-push": {
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "sh \"$(git rev-parse --show-toplevel)/.agents/skills/jig-github-sync/assets/guard-push.sh\""
          }
        ]
      }
    ]
  }
}
EOF
      ;;
  esac > "$template_destination"
}

valid_object() {
  jq -e 'type == "object"' "$1" >/dev/null 2>&1
}

# Prints one of: installed | entry drift | user entry | not installed.
# Requires jq and a valid object file.
entry_state() {
  case "$1" in
    codex)
      jq -r --arg cmd "$GUARD_COMMAND" --arg marker "$CODEX_MARKER" --arg fragment "$GUARD_PATH_FRAGMENT" '
        [ (.hooks.PreToolUse // [])[] | objects | . as $entry | (.hooks // [])[] | objects | {matcher: $entry.matcher, hook: .} ] as $all
        | ($all | map(select(.hook.statusMessage == $marker))) as $mine
        | ($all | map(select(.hook.statusMessage != $marker and ((.hook.command // "") | contains($fragment))))) as $user
        | if ($mine | length) == 0 then (if ($user | length) > 0 then "user entry" else "not installed" end)
          elif ($mine | length) == 1 and $mine[0].matcher == "Bash" and $mine[0].hook.command == $cmd then "installed"
          else "entry drift" end
      ' "$2"
      ;;
    antigravity)
      jq -r --arg cmd "$GUARD_COMMAND" --arg key "$ANTIGRAVITY_KEY" --arg fragment "$GUARD_PATH_FRAGMENT" '
        if has($key) | not then
          ( [ to_entries[] | select(.key != $key) | .value | objects | (.PreToolUse // [])[]? | objects | (.hooks // [])[]? | objects | (.command // "") | select(contains($fragment)) ]
            | if length > 0 then "user entry" else "not installed" end )
        else
          ( .[$key] as $group
            | ($group.PreToolUse // []) as $entries
            | if ($group | type) == "object"
                 and ($group.enabled // true) == true
                 and ($entries | length) == 1
                 and $entries[0].matcher == "run_command"
                 and (($entries[0].hooks // []) | length) == 1
                 and $entries[0].hooks[0].command == $cmd
              then "installed" else "entry drift" end )
        end
      ' "$2"
      ;;
  esac
}

# Removes the jig-owned entry and appends a current one (install) or removes it only
# (uninstall). Prints the resulting document; an empty document prints nothing.
merged_document() {
  merge_host="$1"
  merge_file="$2"
  merge_mode="$3"
  case "$merge_host" in
    codex)
      jq --arg cmd "$GUARD_COMMAND" --arg marker "$CODEX_MARKER" --arg mode "$merge_mode" '
        .hooks = (.hooks // {})
        | .hooks.PreToolUse = ((.hooks.PreToolUse // [])
            | map(if (type == "object") and ((.hooks // []) | any(.[] | objects; .statusMessage == $marker))
                  then (.hooks |= map(select((type == "object" and .statusMessage == $marker) | not)))
                       | (if (.hooks | length) == 0 then empty else . end)
                  else . end))
        | if $mode == "install"
          then .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $cmd, statusMessage: $marker}]}]
          else . end
        | if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end
        | if .hooks == {} then del(.hooks) else . end
        | if . == {} then empty else . end
      ' "$merge_file"
      ;;
    antigravity)
      jq --arg cmd "$GUARD_COMMAND" --arg key "$ANTIGRAVITY_KEY" --arg mode "$merge_mode" '
        del(.[$key])
        | if $mode == "install"
          then . + {($key): {PreToolUse: [{matcher: "run_command", hooks: [{type: "command", command: $cmd}]}]}}
          else . end
        | if . == {} then empty else . end
      ' "$merge_file"
      ;;
  esac
}

write_atomically() {
  atomic_destination="$1"
  atomic_directory=$(dirname "$atomic_destination")
  mkdir -p "$atomic_directory"
  atomic_tmp=$(mktemp "$atomic_directory/.jig-hooks.XXXXXX") || return 1
  if ! cat > "$atomic_tmp" || ! mv "$atomic_tmp" "$atomic_destination"; then
    rm -f "$atomic_tmp"
    return 1
  fi
}

remove_file_and_empty_directory() {
  rm -f "$1" || return 1
  rmdir "$(dirname "$1")" 2>/dev/null || true
}

status_line() {
  status_host="$1"
  status_file=$(hooks_file "$status_host")
  if [ -L "$status_file" ]; then
    printf 'symlink'
    return 0
  fi
  if [ ! -e "$status_file" ]; then
    if host_detected "$status_host"; then printf 'not installed'; else printf 'host not detected'; fi
    return 0
  fi
  if ! have_jq; then
    printf 'jq missing'
    return 0
  fi
  if ! valid_object "$status_file"; then
    printf 'invalid json'
    return 0
  fi
  status_state=$(entry_state "$status_host" "$status_file")
  case "$status_state" in
    installed|"entry drift")
      if ! host_detected "$status_host"; then
        printf 'leftover'
      elif [ ! -f "$GUARD_FILE" ]; then
        printf 'guard missing'
      else
        printf '%s' "$status_state"
      fi
      ;;
    *)
      if host_detected "$status_host"; then printf '%s' "$status_state"; else printf 'host not detected'; fi
      ;;
  esac
}

install_host() {
  install_target="$1"
  install_file=$(hooks_file "$install_target")
  if ! host_detected "$install_target"; then
    say "$install_target: host not detected; skipped"
    return 0
  fi
  [ ! -L "$install_file" ] || fail "$install_target: refusing to manage symlink $install_file"
  [ -f "$GUARD_FILE" ] || fail "$install_target: guard payload missing at $GUARD_FILE; install or update jig first"
  sh -n "$GUARD_FILE" || fail "$install_target: guard payload has invalid shell syntax"

  if [ ! -e "$install_file" ]; then
    install_directory=$(dirname "$install_file")
    mkdir -p "$install_directory"
    install_tmp=$(mktemp "$install_directory/.jig-hooks.XXXXXX") || fail "$install_target: could not create $install_file"
    if ! write_template "$install_target" "$install_tmp" || ! mv "$install_tmp" "$install_file"; then
      rm -f "$install_tmp"
      fail "$install_target: could not install $install_file"
    fi
    say "$install_target: installed $install_file"
    return 0
  fi

  have_jq || fail "$install_target: $install_file exists and jq is not available to merge into it; install jq or add the entry by hand"
  valid_object "$install_file" || fail "$install_target: $install_file is not a JSON object; leaving it unchanged"

  install_state=$(entry_state "$install_target" "$install_file")
  case "$install_state" in
    installed)
      say "$install_target: already current $install_file"
      ;;
    "user entry")
      say "$install_target: a user-owned entry already points at the guard in $install_file; left unchanged"
      ;;
    "not installed"|"entry drift")
      merged_document "$install_target" "$install_file" install | write_atomically "$install_file" || fail "$install_target: could not update $install_file"
      if [ "$install_state" = "entry drift" ]; then
        say "$install_target: updated entry in $install_file"
      else
        say "$install_target: added entry to $install_file"
      fi
      ;;
  esac
}

uninstall_host() {
  uninstall_target="$1"
  uninstall_file=$(hooks_file "$uninstall_target")
  if [ ! -e "$uninstall_file" ] && [ ! -L "$uninstall_file" ]; then
    say "$uninstall_target: already absent $uninstall_file"
    return 0
  fi
  [ ! -L "$uninstall_file" ] || fail "$uninstall_target: refusing to manage symlink $uninstall_file"
  have_jq || fail "$uninstall_target: $uninstall_file exists and jq is not available to edit it; remove the jig entry by hand"
  valid_object "$uninstall_file" || fail "$uninstall_target: $uninstall_file is not a JSON object; leaving it unchanged"

  uninstall_state=$(entry_state "$uninstall_target" "$uninstall_file")
  case "$uninstall_state" in
    "not installed"|"user entry")
      say "$uninstall_target: no jig entry in $uninstall_file; left unchanged"
      return 0
      ;;
  esac

  uninstall_result=$(merged_document "$uninstall_target" "$uninstall_file" uninstall)
  if [ -z "$uninstall_result" ]; then
    remove_file_and_empty_directory "$uninstall_file" || fail "$uninstall_target: could not remove $uninstall_file"
    say "$uninstall_target: removed $uninstall_file (nothing else was in it)"
  else
    printf '%s\n' "$uninstall_result" | write_atomically "$uninstall_file" || fail "$uninstall_target: could not update $uninstall_file"
    say "$uninstall_target: removed jig entry from $uninstall_file"
  fi
}

for host in $HOSTS; do
  case "$MODE" in
    install) install_host "$host" ;;
    uninstall) uninstall_host "$host" ;;
    status) printf '%s: %s\n' "$host" "$(status_line "$host")" ;;
  esac
done
