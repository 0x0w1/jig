#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
MANAGER="$ROOT/skills/github-sync/scripts/manage-pre-push.sh"
SOURCE="$ROOT/skills/github-sync/assets/pre-push"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'pre-push manager tests: %s\n' "$*" >&2
  exit 1
}

new_repository() {
  repository="$1"
  mkdir -p "$repository"
  git -C "$repository" init -q
}

hook_path() {
  git -C "$1" rev-parse --git-common-dir | sed "s|^|$1/|; s|$|/hooks/pre-push|"
}

REPOSITORY="$TEST_ROOT/install"
new_repository "$REPOSITORY"
HOOK=$(hook_path "$REPOSITORY")
(
  cd "$REPOSITORY"
  sh "$MANAGER" install
)
cmp -s "$SOURCE" "$HOOK" || fail "installed hook differs from the managed source"
[ -x "$HOOK" ] || fail "installed hook is not executable"
ZERO=0000000000000000000000000000000000000000
LOCAL=1111111111111111111111111111111111111111
if printf 'refs/heads/topic %s refs/heads/main %s\n' "$LOCAL" "$ZERO" | sh "$HOOK"; then
  fail "hook allowed a direct push to main"
fi
if printf 'refs/heads/main %s refs/heads/main %s\n' "$ZERO" "$LOCAL" | sh "$HOOK"; then
  fail "hook allowed deletion of main"
fi
printf 'refs/heads/topic %s refs/heads/topic %s\n' "$LOCAL" "$ZERO" | sh "$HOOK" || fail "hook blocked an unrelated branch"
printf 'refs/heads/develop %s refs/heads/main %s\n' "$LOCAL" "$ZERO" | sh "$HOOK" || fail "hook blocked the develop:main release form"
(
  cd "$REPOSITORY"
  sh "$MANAGER" install
  sh "$MANAGER" uninstall
)
[ ! -e "$HOOK" ] || fail "uninstall did not remove the jig-owned hook"

REPOSITORY="$TEST_ROOT/update"
new_repository "$REPOSITORY"
HOOK=$(hook_path "$REPOSITORY")
mkdir -p "$(dirname "$HOOK")"
printf '%s\n' '#!/bin/sh' '# jig:pre-push v0' 'exit 0' > "$HOOK"
(
  cd "$REPOSITORY"
  sh "$MANAGER" install
)
cmp -s "$SOURCE" "$HOOK" || fail "an outdated jig hook was not updated"

REPOSITORY="$TEST_ROOT/user-hook"
new_repository "$REPOSITORY"
HOOK=$(hook_path "$REPOSITORY")
mkdir -p "$(dirname "$HOOK")"
printf '%s\n' '#!/bin/sh' 'echo user-hook' > "$HOOK"
cp "$HOOK" "$TEST_ROOT/user-hook-before"
if (
  cd "$REPOSITORY"
  sh "$MANAGER" install
); then
  fail "install replaced a user hook without confirmation"
fi
cmp -s "$TEST_ROOT/user-hook-before" "$HOOK" || fail "blocked install changed the user hook"
(
  cd "$REPOSITORY"
  sh "$MANAGER" install --replace-user-hook
)
cmp -s "$SOURCE" "$HOOK" || fail "confirmed install did not install the jig hook"
[ -f "$HOOK.jig-user-backup" ] || fail "confirmed install did not back up the user hook"
(
  cd "$REPOSITORY"
  sh "$MANAGER" uninstall
)
cmp -s "$TEST_ROOT/user-hook-before" "$HOOK" || fail "uninstall did not restore the user hook"
[ ! -e "$HOOK.jig-user-backup" ] || fail "uninstall left the user-hook backup behind"

REPOSITORY="$TEST_ROOT/custom-hooks-path"
new_repository "$REPOSITORY"
git -C "$REPOSITORY" config core.hooksPath .githooks
if (
  cd "$REPOSITORY"
  sh "$MANAGER" install
); then
  fail "install accepted a user-managed core.hooksPath"
fi
[ ! -e "$REPOSITORY/.git/hooks/pre-push" ] || fail "blocked core.hooksPath install wrote a hook"

REPOSITORY="$TEST_ROOT/symlink-hook"
new_repository "$REPOSITORY"
HOOK=$(hook_path "$REPOSITORY")
mkdir -p "$(dirname "$HOOK")"
ln -s "$SOURCE" "$HOOK"
if (
  cd "$REPOSITORY"
  sh "$MANAGER" install
); then
  fail "install accepted a symlink hook"
fi
[ -L "$HOOK" ] || fail "blocked install changed the symlink hook"

sh -n "$MANAGER"
sh -n "$SOURCE"
echo "pre-push manager tests ok"
