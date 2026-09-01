#!/usr/bin/env sh
set -eu

# Audits a jig-managed repository's history against the procedure jig ships.
# Read-only: it runs git plumbing and writes nothing, so it is safe in CI.
#
# Exit codes: 0 no violations, 1 violations found, 2 usage or environment error.

usage() {
  cat >&2 <<'EOF'
Usage: audit-history.sh [--since <ref>] [--develop <branch>] [--main <branch>] [--quiet]

  --since <ref>    Baseline commit or tag. History before it is not judged.
                   Default: the commit that added .jig/versioning.md, else the
                   oldest vX.Y.Z tag.
  --develop <ref>  Branch carrying ordinary work. Default: develop.
  --main <ref>     Released branch. Default: main.
  --quiet          Print only the summary line and any findings.
EOF
  exit 2
}

abort() {
  printf 'conformance-audit: %s\n' "$*" >&2
  exit 2
}

SINCE=""
DEVELOP="develop"
MAIN="main"
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --since) [ "$#" -ge 2 ] || usage; SINCE="$2"; shift 2 ;;
    --develop) [ "$#" -ge 2 ] || usage; DEVELOP="$2"; shift 2 ;;
    --main) [ "$#" -ge 2 ] || usage; MAIN="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || abort "not a git repository"

VIOLATIONS=0
NOTES=0
REPORT=$(mktemp) || abort "cannot create a temporary file"
trap 'rm -f "$REPORT"' EXIT

violation() {
  VIOLATIONS=$((VIOLATIONS + 1))
  printf 'violation  %s\n' "$*" >> "$REPORT"
}

note() {
  NOTES=$((NOTES + 1))
  printf 'note       %s\n' "$*" >> "$REPORT"
}

detail() {
  printf '           %s\n' "$*" >> "$REPORT"
}

say() {
  [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"
}

ref_exists() {
  git rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

# Prefers the remote-tracking ref when it exists: a stale local branch would
# otherwise make the audit judge history the remote no longer has.
resolve_branch() {
  if ref_exists "refs/remotes/origin/$1"; then
    printf 'origin/%s' "$1"
  elif ref_exists "refs/heads/$1"; then
    printf '%s' "$1"
  elif ref_exists "$1"; then
    printf '%s' "$1"
  else
    printf ''
  fi
}

# Ordered oldest to newest by git's own version comparison, so v0.9.0 sorts
# before v0.11.0 instead of after it the way a lexical sort would put it.
version_tags() {
  git tag --list 'v*' --sort=v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true
}

# The baseline is what keeps history written before jig was installed out of the
# findings. Without it every adopting repository reports as broken on day one.
resolve_baseline() {
  if [ -n "$SINCE" ]; then
    printf '%s explicit' "$(git rev-parse "$SINCE")"
    return 0
  fi

  adoption=$(git log --diff-filter=A --format='%H' -- .jig/versioning.md 2>/dev/null | tail -1)
  if [ -n "$adoption" ]; then
    printf '%s rubric-commit' "$adoption"
    return 0
  fi

  oldest_tag=$(version_tags | head -1)
  if [ -n "$oldest_tag" ]; then
    printf '%s oldest-tag' "$(git rev-parse "$oldest_tag^{commit}")"
    return 0
  fi

  return 1
}

# Checked before resolve_baseline runs: an abort inside that subshell would only
# end the subshell and surface as the generic "cannot determine a baseline".
if [ -n "$SINCE" ]; then
  ref_exists "$SINCE" || abort "unknown --since ref: $SINCE"
fi

DEVELOP_REF=$(resolve_branch "$DEVELOP")
MAIN_REF=$(resolve_branch "$MAIN")
[ -n "$DEVELOP_REF" ] || abort "no such branch: $DEVELOP"

if ! baseline_pair=$(resolve_baseline); then
  abort "cannot determine a baseline: pass --since <ref>"
fi
BASELINE=${baseline_pair% *}
BASELINE_SOURCE=${baseline_pair##* }

say "conformance-audit"
say "  baseline: $(git rev-parse --short "$BASELINE") ($BASELINE_SOURCE)"
say "  develop:  $DEVELOP_REF"
say "  main:     ${MAIN_REF:-not found}"
say ""

# --- subject-prefix and subject-type ------------------------------------------
# The squash subject is the release-note source. A subject with no conventional
# type drops out of the notes; a type outside the seven this project documents
# still renders, but into a section of its own.
JIG_TYPES='feat|fix|chore|docs|refactor|test|ci'
SHAPE='^[a-z][a-z-]*(\([^()]+\))?!?: .'

subject_total=0
subject_shapeless=$(mktemp) || abort "cannot create a temporary file"
subject_offlist=$(mktemp) || abort "cannot create a temporary file"
trap 'rm -f "$REPORT" "$subject_shapeless" "$subject_offlist"' EXIT

while IFS= read -r line; do
  [ -n "$line" ] || continue
  subject_total=$((subject_total + 1))
  subject=${line#* }
  if ! printf '%s\n' "$subject" | grep -qE "$SHAPE"; then
    printf '%s\n' "$line" >> "$subject_shapeless"
  elif ! printf '%s\n' "$subject" | grep -qE "^(${JIG_TYPES})(\\([^()]+\\))?!?: "; then
    printf '%s\n' "$line" >> "$subject_offlist"
  fi
done <<EOF
$(git log --no-merges --format='%h %s' "$BASELINE..$DEVELOP_REF" 2>/dev/null || true)
EOF

report_lines() {
  head -5 "$1" | while IFS= read -r reported; do
    detail "$reported"
  done
  extra=$(($(wc -l < "$1" | tr -d ' ') - 5))
  [ "$extra" -le 0 ] || detail "... and $extra more"
}

if [ -s "$subject_shapeless" ]; then
  shapeless_count=$(wc -l < "$subject_shapeless" | tr -d ' ')
  violation "subject-prefix: $shapeless_count of $subject_total commits on $DEVELOP have no conventional type"
  report_lines "$subject_shapeless"
fi

if [ -s "$subject_offlist" ]; then
  offlist_count=$(wc -l < "$subject_offlist" | tr -d ' ')
  note "subject-type: $offlist_count of $subject_total commits use a type outside $JIG_TYPES"
  report_lines "$subject_offlist"
fi

# --- grade-coverage and grade-value -------------------------------------------
# github-release reads the highest Release-Grade trailer in the release range as a
# floor it never lowers. When no commit carries one the floor evaluates to nothing
# and the release grades from paths alone, without saying so.
latest_tag=$(version_tags | tail -1)
if [ -n "$latest_tag" ]; then
  grade_range="$latest_tag..$DEVELOP_REF"
  grade_range_label="since $latest_tag"
else
  grade_range="$BASELINE..$DEVELOP_REF"
  grade_range_label="since the baseline"
fi

grade_total=0
grade_present=0
grade_bad=0
while IFS= read -r commit; do
  [ -n "$commit" ] || continue
  grade_total=$((grade_total + 1))
  value=$(git show -s --format='%(trailers:key=Release-Grade,valueonly)' "$commit" | tr -d '\r' | sed '/^$/d')
  [ -n "$value" ] || continue
  grade_present=$((grade_present + 1))
  count=$(printf '%s\n' "$value" | wc -l | tr -d ' ')
  case "$value" in
    patch|minor|major) [ "$count" -eq 1 ] || grade_bad=$((grade_bad + 1)) ;;
    *) grade_bad=$((grade_bad + 1)) ;;
  esac
done <<EOF
$(git log --no-merges --format='%H' "$grade_range" 2>/dev/null || true)
EOF

if [ "$grade_total" -eq 0 ]; then
  say "  no unreleased commits to grade"
elif [ "$grade_present" -eq 0 ]; then
  violation "grade-coverage: 0 of $grade_total unreleased commits carry Release-Grade ($grade_range_label)"
  detail "the release grade floor evaluates to nothing and the release does not report it"
elif [ "$grade_present" -lt "$grade_total" ]; then
  note "grade-coverage: $grade_present of $grade_total unreleased commits carry Release-Grade ($grade_range_label)"
fi

if [ "$grade_bad" -gt 0 ]; then
  violation "grade-value: $grade_bad commit(s) carry a Release-Grade that is not one lowercase patch|minor|major"
fi

# --- tag-format ---------------------------------------------------------------
bad_tags=$(git tag --list | grep -vE '^v[0-9]+\.[0-9]+\.[0-9]+$' || true)
if [ -n "$bad_tags" ]; then
  bad_tag_count=$(printf '%s\n' "$bad_tags" | sed '/^$/d' | wc -l | tr -d ' ')
  violation "tag-format: $bad_tag_count tag(s) do not match ^v[0-9]+\\.[0-9]+\\.[0-9]+\$"
  printf '%s\n' "$bad_tags" | sed '/^$/d' | head -5 | while IFS= read -r bad_tag; do
    detail "$bad_tag"
  done
fi

# --- tag-on-main --------------------------------------------------------------
# A release tags the commit main was fast-forwarded to. A version tag that main
# cannot reach means the tag was cut somewhere else.
if [ -n "$MAIN_REF" ]; then
  orphan_tags=""
  orphan_count=0
  for tag in $(version_tags); do
    tag_commit=$(git rev-parse --verify --quiet "$tag^{commit}") || continue
    git merge-base --is-ancestor "$BASELINE" "$tag_commit" 2>/dev/null || continue
    if ! git merge-base --is-ancestor "$tag_commit" "$MAIN_REF" 2>/dev/null; then
      orphan_count=$((orphan_count + 1))
      orphan_tags="$orphan_tags $tag"
    fi
  done
  if [ "$orphan_count" -gt 0 ]; then
    violation "tag-on-main: $orphan_count version tag(s) are not reachable from $MAIN"
    detail "$(printf '%s' "${orphan_tags# }")"
  fi
fi

# --- main-ancestry and main-lineage -------------------------------------------
# github-release promotes with a fast-forward push, so main must stay an ancestor
# of develop. hotfix-flow breaks that on purpose and restores it in its last step.
if [ -n "$MAIN_REF" ]; then
  if git merge-base --is-ancestor "$MAIN_REF" "$DEVELOP_REF" 2>/dev/null; then
    say "  release invariant: $MAIN is an ancestor of $DEVELOP"
  else
    violation "main-ancestry: $MAIN is not an ancestor of $DEVELOP, so the next release cannot fast-forward"
    detail "run hotfix-flow step 8 (git merge $MAIN into $DEVELOP) before releasing"
    stray=$(git log --no-merges --format='%h %s' "$DEVELOP_REF..$MAIN_REF" 2>/dev/null | head -5 || true)
    if [ -n "$stray" ]; then
      stray_count=$(git rev-list --no-merges --count "$DEVELOP_REF..$MAIN_REF" 2>/dev/null || echo 0)
      violation "main-lineage: $stray_count commit(s) on $MAIN are not reachable from $DEVELOP"
      printf '%s\n' "$stray" | while IFS= read -r stray_line; do
        detail "$stray_line"
      done
    fi
  fi
fi

# --- rubric-tracked -----------------------------------------------------------
# The rubric only governs a release when it reaches clones and CI; an untracked
# file grades on one machine and nowhere else.
rubric=".jig/versioning.md"
if [ -n "${JIG_VERSION_RUBRIC:-}" ]; then
  rubric="$JIG_VERSION_RUBRIC"
elif configured=$(git config --local --get jig.versionRubric 2>/dev/null) && [ -n "$configured" ]; then
  rubric="$configured"
fi

if [ ! -f "$rubric" ]; then
  note "rubric-tracked: no version rubric at $rubric; run version-rubric to settle one"
elif ! git ls-files --error-unmatch "$rubric" >/dev/null 2>&1; then
  note "rubric-tracked: $rubric is untracked, so it does not reach clones or CI"
elif ! git diff --quiet -- "$rubric" 2>/dev/null; then
  note "rubric-tracked: $rubric has uncommitted changes"
fi

# --- report -------------------------------------------------------------------
if [ -s "$REPORT" ]; then
  cat "$REPORT"
  say ""
fi

printf 'conformance-audit: %d violation(s), %d note(s), baseline %s (%s)\n' \
  "$VIOLATIONS" "$NOTES" "$(git rev-parse --short "$BASELINE")" "$BASELINE_SOURCE"

[ "$VIOLATIONS" -eq 0 ] || exit 1
exit 0
