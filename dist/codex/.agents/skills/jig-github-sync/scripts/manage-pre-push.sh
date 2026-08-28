#!/usr/bin/env sh
set -eu

usage() {
  cat >&2 <<'EOF'
Usage: manage-pre-push.sh install [--replace-user-hook]
       manage-pre-push.sh uninstall
EOF
  exit 2
}

fail() {
  printf 'jig pre-push manager: %s\n' "$*" >&2
  exit 1
}

owned_by_jig() {
  owned_file="$1"
  [ -f "$owned_file" ] || return 1
  owned_marker=$(sed -n '2p' "$owned_file")
  case "$owned_marker" in
    '# jig:pre-push v'*) ;;
    *) return 1 ;;
  esac
  owned_version=${owned_marker#\# jig:pre-push v}
  case "$owned_version" in
    ''|*[!0-9]*) return 1 ;;
  esac
}

write_hook() {
  write_destination="$1"
  write_directory=$(dirname "$write_destination")
  mkdir -p "$write_directory"
  write_tmp=$(mktemp "$write_directory/.jig-pre-push.XXXXXX") || return 1
  if ! cp "$HOOK_SOURCE" "$write_tmp" || ! chmod +x "$write_tmp" || ! mv "$write_tmp" "$write_destination"; then
    rm -f "$write_tmp"
    return 1
  fi
}

[ "$#" -ge 1 ] || usage
MODE="$1"
shift

REPLACE_USER_HOOK=0
case "$MODE" in
  install)
    if [ "$#" -eq 1 ] && [ "$1" = "--replace-user-hook" ]; then
      REPLACE_USER_HOOK=1
      shift
    fi
    [ "$#" -eq 0 ] || usage
    ;;
  uninstall)
    [ "$#" -eq 0 ] || usage
    ;;
  *) usage ;;
esac

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "the current directory is not inside a Git worktree"

SCRIPT_DIRECTORY=$(CDPATH= cd "$(dirname "$0")" && pwd)
HOOK_SOURCE="$SCRIPT_DIRECTORY/../assets/pre-push"
[ -f "$HOOK_SOURCE" ] || fail "managed hook source is missing: $HOOK_SOURCE"
sh -n "$HOOK_SOURCE" || fail "managed hook source has invalid shell syntax"

GIT_COMMON_DIRECTORY=$(git rev-parse --git-common-dir)
HOOK_PATH="$GIT_COMMON_DIRECTORY/hooks/pre-push"
USER_BACKUP="$HOOK_PATH.jig-user-backup"

[ ! -L "$HOOK_PATH" ] || fail "refusing to manage symlink hook: $HOOK_PATH"
[ ! -L "$USER_BACKUP" ] || fail "refusing to manage symlink backup: $USER_BACKUP"

if [ "$MODE" = "install" ]; then
  CONFIGURED_HOOKS_PATH=$(git config --get core.hooksPath 2>/dev/null || true)
  if [ -n "$CONFIGURED_HOOKS_PATH" ]; then
    fail "core.hooksPath is set to $CONFIGURED_HOOKS_PATH; refusing to install into a user-managed hook directory"
  fi

  if [ ! -e "$HOOK_PATH" ]; then
    write_hook "$HOOK_PATH" || fail "could not install $HOOK_PATH"
    printf 'jig pre-push manager: installed %s\n' "$HOOK_PATH"
    exit 0
  fi

  if cmp -s "$HOOK_SOURCE" "$HOOK_PATH"; then
    if [ ! -x "$HOOK_PATH" ]; then
      chmod +x "$HOOK_PATH" || fail "could not make $HOOK_PATH executable"
      printf 'jig pre-push manager: repaired executable permission on %s\n' "$HOOK_PATH"
    else
      printf 'jig pre-push manager: already current %s\n' "$HOOK_PATH"
    fi
    exit 0
  fi

  if owned_by_jig "$HOOK_PATH"; then
    previous_version="$owned_version"
    write_hook "$HOOK_PATH" || fail "could not update $HOOK_PATH"
    printf 'jig pre-push manager: updated v%s to current at %s\n' "$previous_version" "$HOOK_PATH"
    exit 0
  fi

  if [ "$REPLACE_USER_HOOK" -ne 1 ]; then
    fail "a user-owned pre-push hook already exists at $HOOK_PATH; rerun with --replace-user-hook only after explicit confirmation"
  fi
  [ ! -e "$USER_BACKUP" ] || fail "refusing to overwrite existing backup: $USER_BACKUP"

  mv "$HOOK_PATH" "$USER_BACKUP" || fail "could not back up the user hook to $USER_BACKUP"
  if ! write_hook "$HOOK_PATH"; then
    mv "$USER_BACKUP" "$HOOK_PATH" || true
    fail "installation failed; attempted to restore the user hook"
  fi
  printf 'jig pre-push manager: installed %s; user hook backed up at %s\n' "$HOOK_PATH" "$USER_BACKUP"
  exit 0
fi

if [ ! -e "$HOOK_PATH" ]; then
  if [ -e "$USER_BACKUP" ]; then
    mv "$USER_BACKUP" "$HOOK_PATH" || fail "could not restore $USER_BACKUP"
    printf 'jig pre-push manager: restored user hook to %s\n' "$HOOK_PATH"
  else
    printf 'jig pre-push manager: already absent %s\n' "$HOOK_PATH"
  fi
  exit 0
fi

if ! owned_by_jig "$HOOK_PATH"; then
  fail "the hook at $HOOK_PATH is not jig-owned; leaving it unchanged"
fi

rm -f "$HOOK_PATH" || fail "could not remove $HOOK_PATH"
if [ -e "$USER_BACKUP" ]; then
  mv "$USER_BACKUP" "$HOOK_PATH" || fail "removed the jig hook but could not restore $USER_BACKUP"
  printf 'jig pre-push manager: removed jig hook and restored user hook at %s\n' "$HOOK_PATH"
else
  printf 'jig pre-push manager: removed %s\n' "$HOOK_PATH"
fi
