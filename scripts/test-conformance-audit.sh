#!/usr/bin/env sh
set -eu

# Exercises skills/conformance-audit/scripts/audit-history.sh against throwaway
# repositories, one fixture per check, including the paths that must stay quiet.

AUDIT=$(cd "$(dirname "$0")/.." && pwd)/skills/conformance-audit/scripts/audit-history.sh
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

failures=0

fail() {
  printf 'conformance-audit tests: %s\n' "$*" >&2
  failures=$((failures + 1))
}

commit() {
  printf '%s\n' "$2" >> file.txt
  git add file.txt
  git commit --quiet -m "$1"
}

new_repo() {
  repo="$WORK/$1"
  mkdir -p "$repo"
  cd "$repo"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "jig test"
  git config commit.gpgsign false
}

adopt_jig() {
  mkdir -p .jig
  printf '# rubric\n' > .jig/versioning.md
  git add .jig/versioning.md
  git commit --quiet -m "chore: adopt the jig version rubric"
}

run_audit() {
  set +e
  audit_output=$("$@" 2>&1)
  audit_status=$?
  set -e
}

expect_status() {
  [ "$audit_status" -eq "$1" ] || fail "$2: expected exit $1, got $audit_status
$audit_output"
}

expect_text() {
  printf '%s\n' "$audit_output" | grep -F "$1" >/dev/null 2>&1 ||
    fail "$2: expected output to contain '$1'
$audit_output"
}

expect_no_text() {
  if printf '%s\n' "$audit_output" | grep -F "$1" >/dev/null 2>&1; then
    fail "$2: expected output not to contain '$1'
$audit_output"
  fi
}

# --- a conforming repository stays silent -------------------------------------
new_repo clean
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
commit "feat: add a thing

Release-Grade: minor" two
run_audit sh "$AUDIT"
expect_status 0 clean
expect_text "0 violation(s), 0 note(s)" clean

# --- history written before adoption is not judged ----------------------------
new_repo baseline
commit "sloppy message with no type" one
commit "another one" two
adopt_jig
git branch develop
git checkout --quiet develop
commit "feat: first jig-era commit

Release-Grade: patch" three
run_audit sh "$AUDIT"
expect_status 0 baseline
expect_no_text "subject-prefix" baseline

# --- an explicit baseline overrides the detected one --------------------------
run_audit sh "$AUDIT" --since "$(git rev-list --max-parents=0 HEAD)"
expect_status 1 explicit-baseline
expect_text "subject-prefix" explicit-baseline
expect_text "(explicit)" explicit-baseline

# --- a subject with no conventional type is a violation -----------------------
new_repo subject
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
commit "make the thing faster

Release-Grade: patch" two
run_audit sh "$AUDIT"
expect_status 1 subject-prefix
expect_text "subject-prefix: 1 of 1 commits" subject-prefix

# --- a type outside the documented seven is a note, not a violation -----------
new_repo offlist
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
commit "perf: tighten the loop

Release-Grade: patch" two
run_audit sh "$AUDIT"
expect_status 0 subject-type
expect_text "subject-type: 1 of 1 commits" subject-type

# --- no Release-Grade anywhere in the release range is a violation ------------
new_repo grades
commit "chore: seed" one
adopt_jig
git tag v0.1.0
git branch develop
git checkout --quiet develop
commit "feat: ungraded work" two
commit "fix: more ungraded work" three
run_audit sh "$AUDIT"
expect_status 1 grade-coverage
expect_text "grade-coverage: 0 of 2" grade-coverage

# --- partial coverage is a note ------------------------------------------------
commit "docs: graded work

Release-Grade: patch" four
run_audit sh "$AUDIT"
expect_status 0 grade-partial
expect_text "grade-coverage: 1 of 3" grade-partial

# --- a malformed Release-Grade value is a violation ---------------------------
new_repo grade-value
commit "chore: seed" one
adopt_jig
git tag v0.1.0
git branch develop
git checkout --quiet develop
commit "feat: wrongly graded

Release-Grade: Minor" two
run_audit sh "$AUDIT"
expect_status 1 grade-value
expect_text "grade-value: 1 commit(s)" grade-value

# --- a tag outside vX.Y.Z is a violation --------------------------------------
new_repo tags
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
git tag release-2026-01
run_audit sh "$AUDIT"
expect_status 1 tag-format
expect_text "tag-format: 1 tag(s)" tag-format

# --- a version tag main cannot reach is a violation ---------------------------
new_repo tag-on-main
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
commit "feat: unreleased work

Release-Grade: minor" two
git tag v0.2.0
run_audit sh "$AUDIT"
expect_status 1 tag-on-main
expect_text "tag-on-main: 1 version tag(s)" tag-on-main

# --- main ahead of develop breaks the release invariant -----------------------
new_repo ancestry
commit "chore: seed" one
adopt_jig
git branch develop
commit "fix: land a hotfix straight on main

Release-Grade: patch" two
git checkout --quiet develop
commit "feat: ordinary work

Release-Grade: minor" three
run_audit sh "$AUDIT"
expect_status 1 main-ancestry
expect_text "main-ancestry" main-ancestry
expect_text "main-lineage: 1 commit(s)" main-ancestry

# --- an untracked rubric is a note --------------------------------------------
new_repo rubric
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
printf '# changed\n' >> .jig/versioning.md
run_audit sh "$AUDIT"
expect_status 0 rubric-tracked
expect_text "rubric-tracked" rubric-tracked

# --- no baseline and no tags is a usage error, not a pass ---------------------
new_repo no-baseline
commit "chore: seed" one
git branch develop
run_audit sh "$AUDIT"
expect_status 2 no-baseline
expect_text "cannot determine a baseline" no-baseline

# --- an unknown --since ref names itself --------------------------------------
new_repo bad-since
commit "chore: seed" one
adopt_jig
git branch develop
run_audit sh "$AUDIT" --since no-such-ref
expect_status 2 bad-since
expect_text "unknown --since ref: no-such-ref" bad-since
expect_no_text "cannot determine a baseline" bad-since

# --- the release range uses version order, not lexical order ------------------
new_repo tag-order
commit "chore: seed" one
adopt_jig
git branch develop
git checkout --quiet develop
commit "feat: released under 0.9

Release-Grade: minor" two
git tag v0.9.0
commit "feat: released under 0.11

Release-Grade: minor" three
git tag v0.11.0
git checkout --quiet main
git merge --quiet --ff-only develop
git checkout --quiet develop
commit "fix: ungraded work after the newest tag" four
run_audit sh "$AUDIT"
expect_status 1 tag-order
# A lexical sort would call v0.9.0 the latest and count three commits in the range.
expect_text "grade-coverage: 0 of 1" tag-order

# --- a missing develop branch is a usage error --------------------------------
new_repo no-develop
commit "chore: seed" one
adopt_jig
run_audit sh "$AUDIT"
expect_status 2 no-develop
expect_text "no such branch: develop" no-develop

# --- outside a repository it refuses rather than guessing ---------------------
mkdir -p "$WORK/plain"
cd "$WORK/plain"
run_audit sh "$AUDIT"
expect_status 2 not-a-repo
expect_text "not a git repository" not-a-repo

if [ "$failures" -gt 0 ]; then
  printf 'conformance-audit tests: %d failure(s)\n' "$failures" >&2
  exit 1
fi

echo "conformance-audit tests ok"
