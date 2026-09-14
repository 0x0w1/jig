#!/usr/bin/env sh
set -eu

# Regression tests for the repo-hygiene branch classifier. Every case builds a real
# repository and runs real git commands, because the defect being guarded against was a
# wrong reading of git's own diff semantics, not a missing string in a document.

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
CLASSIFY="$ROOT/skills/repo-hygiene/scripts/classify-branches.sh"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'repo-hygiene branch tests: %s\n' "$*" >&2
  exit 1
}

new_repository() {
  repository="$TEST_ROOT/$1"
  rm -rf "$repository"
  mkdir -p "$repository"
  git -C "$repository" init -q -b main
  git -C "$repository" config user.email test@example.com
  git -C "$repository" config user.name test
  printf 'base\n' > "$repository/a.txt"
  printf 'base\n' > "$repository/b.txt"
  git -C "$repository" add -A
  git -C "$repository" commit -qm "base"
  git -C "$repository" branch develop
  git -C "$repository" checkout -q develop
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -qm "$2"
}

# Runs the classifier from inside the repository and prints the status for one branch.
status_of() {
  (cd "$1" && sh "$CLASSIFY" ${3:+--history-limit "$3"}) | awk -F '\t' -v b="$2" '$2 == b { print $1 }'
}

detail_of() {
  (cd "$1" && sh "$CLASSIFY") | awk -F '\t' -v b="$2" '$2 == b { print $3 }'
}

expect_status() {
  actual=$(status_of "$1" "$2" "${4:-}")
  [ "$actual" = "$3" ] || fail "$5: expected $3 for $2, got '${actual:-<none>}'"
}

# --- Case 1: squash merged, both branches hold identical content -------------------
# This is the case the shipped rule got wrong, so the old rule is asserted to fail here.
R="$TEST_ROOT/squash-clean"
new_repository squash-clean
git -C "$R" checkout -q -b feature/x
printf 'work\n' > "$R/a.txt"
printf 'new\n' > "$R/c.txt"
commit_all "$R" "work"
git -C "$R" checkout -q develop
git -C "$R" merge --squash feature/x >/dev/null
commit_all "$R" "feat: work"

if git -C "$R" diff --quiet develop...feature/x; then
  fail "case 1 fixture is wrong: the retired three-dot rule already reports an empty diff"
fi
expect_status "$R" feature/x incorporated "" "case 1 (squash merged, identical content)"

# --- Case 2: squash merged, then unrelated work lands on develop -------------------
# This is the case a plain two-dot diff would get wrong, so that variant is asserted too.
printf 'unrelated\n' > "$R/d.txt"
commit_all "$R" "chore: unrelated"
if git -C "$R" diff --quiet develop..feature/x; then
  fail "case 2 fixture is wrong: the two-dot variant already reports an empty diff"
fi
expect_status "$R" feature/x incorporated "" "case 2 (unrelated commit on develop after the squash)"

# --- Case 3: new work added to the task branch after the merge ---------------------
git -C "$R" checkout -q feature/x
printf 'work2\n' > "$R/a.txt"
commit_all "$R" "more work"
git -C "$R" checkout -q develop
expect_status "$R" feature/x unincorporated "" "case 3 (branch moved on after the merge)"
case "$(detail_of "$R" feature/x)" in
  *a.txt*) ;;
  *) fail "case 3: the detail does not name the path that differs" ;;
esac

# --- Case 4: only part of the branch landed ----------------------------------------
R="$TEST_ROOT/partial"
new_repository partial
git -C "$R" checkout -q -b feature/partial
printf 'changed\n' > "$R/a.txt"
printf 'changed\n' > "$R/b.txt"
commit_all "$R" "two files"
git -C "$R" checkout -q develop
printf 'changed\n' > "$R/a.txt"
commit_all "$R" "feat: only one of the two files"
expect_status "$R" feature/partial unincorporated "" "case 4 (only part of the branch landed)"
case "$(detail_of "$R" feature/partial)" in
  *"1 of 2"*) ;;
  *) fail "case 4: the detail does not report 1 of 2 changed paths outstanding" ;;
esac

# A branch mixing a definitely-missing path with an undecidable one reports the fact it
# is sure of, and names the rest, rather than hiding the missing work behind "unknown".
R="$TEST_ROOT/mixed"
new_repository mixed
git -C "$R" checkout -q -b feature/mixed
printf 'branch-a\n' > "$R/a.txt"
printf 'branch-b\n' > "$R/b.txt"
commit_all "$R" "two files"
git -C "$R" checkout -q develop
printf 'develop-a\n' > "$R/a.txt"
commit_all "$R" "feat: develop takes a different a.txt"
expect_status "$R" feature/mixed unincorporated "" "mixed missing and undecidable"
case "$(detail_of "$R" feature/mixed)" in
  *undecidable*) ;;
  *) fail "mixed branch: the detail does not mention the undecidable path" ;;
esac

# --- Case 5a: merged, then reverted on develop -------------------------------------
R="$TEST_ROOT/reverted"
new_repository reverted
git -C "$R" checkout -q -b feature/reverted
printf 'work\n' > "$R/a.txt"
commit_all "$R" "work"
git -C "$R" checkout -q develop
git -C "$R" merge --squash feature/reverted >/dev/null
commit_all "$R" "feat: work"
printf 'base\n' > "$R/a.txt"
commit_all "$R" "revert: back to base"
expect_status "$R" feature/reverted undecidable "" "case 5a (merged then reverted)"

# --- Case 5b: merged, then develop built further on the same path ------------------
# Historical equality cannot distinguish later extension from a partial revert.
# This conservative classifier leaves differing versions for human review.
R="$TEST_ROOT/superseded"
new_repository superseded
git -C "$R" checkout -q -b feature/superseded
printf 'work\n' > "$R/a.txt"
commit_all "$R" "work"
git -C "$R" checkout -q develop
git -C "$R" merge --squash feature/superseded >/dev/null
commit_all "$R" "feat: work"
printf 'work-plus\n' > "$R/a.txt"
commit_all "$R" "feat: build on it"
expect_status "$R" feature/superseded undecidable "" "case 5b (merged then built on)"

# --- Case 5c: develop changed the same path without ever taking the branch ---------
R="$TEST_ROOT/conflicting"
new_repository conflicting
git -C "$R" checkout -q -b feature/conflicting
printf 'branch-version\n' > "$R/a.txt"
commit_all "$R" "branch version"
git -C "$R" checkout -q develop
printf 'develop-version\n' > "$R/a.txt"
commit_all "$R" "feat: develop version"
expect_status "$R" feature/conflicting undecidable "" "case 5c (both changed the path, never merged)"

# --- Never merged at all -----------------------------------------------------------
R="$TEST_ROOT/never"
new_repository never
git -C "$R" checkout -q -b feature/never
printf 'work\n' > "$R/a.txt"
commit_all "$R" "work"
git -C "$R" checkout -q develop
expect_status "$R" feature/never unincorporated "" "never merged"

# --- Branch that adds nothing beyond develop ---------------------------------------
R="$TEST_ROOT/empty"
new_repository empty
git -C "$R" checkout -q -b chore/empty
git -C "$R" checkout -q develop
expect_status "$R" chore/empty incorporated "" "branch with no commits of its own"

# --- Deletion carried by the branch ------------------------------------------------
R="$TEST_ROOT/deletion"
new_repository deletion
git -C "$R" checkout -q -b chore/deletion
git -C "$R" rm -q b.txt
commit_all "$R" "drop b"
git -C "$R" checkout -q develop
expect_status "$R" chore/deletion unincorporated "" "deletion not yet landed"
git -C "$R" rm -q b.txt
commit_all "$R" "chore: drop b"
expect_status "$R" chore/deletion incorporated "" "deletion landed by squash"

# --- Protected refs are never classified -------------------------------------------
R="$TEST_ROOT/protected"
new_repository protected
git -C "$R" checkout -q -b feature/current
printf 'work\n' > "$R/a.txt"
commit_all "$R" "work"
protected_output=$(cd "$R" && sh "$CLASSIFY" develop main feature/current)
printf '%s\n' "$protected_output" | awk -F '\t' '$2 == "develop" && $1 == "protected"' | grep -q . \
  || fail "develop was not reported as protected"
printf '%s\n' "$protected_output" | awk -F '\t' '$2 == "main" && $1 == "protected"' | grep -q . \
  || fail "main was not reported as protected"
printf '%s\n' "$protected_output" | awk -F '\t' '$2 == "feature/current" && $1 == "protected"' | grep -q . \
  || fail "the current branch was not reported as protected"

# --- A truncated history search is undecidable, never unincorporated ---------------
R="$TEST_ROOT/truncated"
new_repository truncated
git -C "$R" checkout -q -b feature/deep
printf 'work\n' > "$R/a.txt"
commit_all "$R" "work"
git -C "$R" checkout -q develop
i=0
while [ "$i" -lt 4 ]; do
  printf 'develop-%s\n' "$i" > "$R/a.txt"
  commit_all "$R" "chore: churn $i"
  i=$((i + 1))
done
expect_status "$R" feature/deep undecidable 2 "history limit reached"
expect_status "$R" feature/deep undecidable 50 "develop changed the path independently"

# --- Only task-branch prefixes are classified by default ---------------------------
R="$TEST_ROOT/prefixes"
new_repository prefixes
git -C "$R" branch personal/scratch
git -C "$R" branch feature/real
default_output=$(cd "$R" && sh "$CLASSIFY")
printf '%s\n' "$default_output" | awk -F '\t' '$2 == "feature/real"' | grep -q . \
  || fail "feature/real was not classified by default"
if printf '%s\n' "$default_output" | awk -F '\t' '$2 == "personal/scratch"' | grep -q .; then
  fail "a branch outside the task prefixes was classified by default"
fi

# --- A partial revert is not evidence the whole task still stands ------------------
R="$TEST_ROOT/partial-revert"
new_repository partial-revert
git -C "$R" checkout -q -b feature/partial-revert
printf 'first\nsecond\n' > "$R/a.txt"
commit_all "$R" "two changes"
git -C "$R" checkout -q develop
git -C "$R" merge --squash feature/partial-revert >/dev/null
commit_all "$R" "feat: two changes"
printf 'first\n' > "$R/a.txt"
commit_all "$R" "revert: only second change"
expect_status "$R" feature/partial-revert undecidable "" "partial revert after squash"

# --- Mode-only work must not disappear behind an equal blob ------------------------
R="$TEST_ROOT/mode"
new_repository mode
git -C "$R" checkout -q -b feature/mode
chmod +x "$R/a.txt"
git -C "$R" update-index --chmod=+x a.txt
git -C "$R" commit -qm "make executable"
git -C "$R" checkout -q develop
expect_status "$R" feature/mode unincorporated "" "mode change not landed"
git -C "$R" merge --squash feature/mode >/dev/null
commit_all "$R" "feat: executable"
expect_status "$R" feature/mode incorporated "" "mode change landed"

# --- Quoted names cannot silently compare as two absent paths ----------------------
R="$TEST_ROOT/quoted"
new_repository quoted
git -C "$R" checkout -q -b feature/quoted
printf 'work\n' > "$R/$(printf 'line\nbreak')"
commit_all "$R" "newline path"
git -C "$R" checkout -q develop
expect_status "$R" feature/quoted undecidable "" "quoted newline path"

# --- Rename detection must retain the removed source -------------------------------
R="$TEST_ROOT/rename"
new_repository rename
git -C "$R" checkout -q -b feature/rename
git -C "$R" mv a.txt renamed.txt
commit_all "$R" "rename a"
git -C "$R" checkout -q develop
cp "$R/a.txt" "$R/renamed.txt"
commit_all "$R" "copy only"
expect_status "$R" feature/rename unincorporated "" "rename source still exists"

# --- develop stays protected with a different base or fully qualified name ---------
R="$TEST_ROOT/custom-base"
new_repository custom-base
git -C "$R" checkout -q main
for ref in develop refs/heads/develop refs/heads/main; do
  output=$(cd "$R" && sh "$CLASSIFY" --base main "$ref")
  [ "$(printf '%s' "$output" | cut -f1)" = protected ] || fail "custom base did not protect $ref"
done

# --- Usage errors ------------------------------------------------------------------
R="$TEST_ROOT/usage"
new_repository usage
if (cd "$R" && sh "$CLASSIFY" --base no-such-branch >/dev/null 2>&1); then
  fail "a missing base ref was accepted"
fi
if (cd "$R" && sh "$CLASSIFY" --history-limit 0 >/dev/null 2>&1); then
  fail "a zero history limit was accepted"
fi

sh -n "$CLASSIFY"
echo "repo-hygiene branch tests ok"
