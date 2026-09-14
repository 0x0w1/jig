#!/usr/bin/env sh
set -eu

# Read-only, conservative squash-content classification. Compare only paths changed
# by the task, including mode/type and deletions. History can explain a difference,
# but never turns a difference into permission to offer deletion.
# Output: status<TAB>branch<TAB>detail. Exit 0: classified; 2: usage/Git error.
usage() {
  echo 'Usage: classify-branches.sh [--base <ref>] [--history-limit <n>] [<local-branch>...]' >&2
  exit 2
}
fail() { printf 'classify-branches: %s\n' "$*" >&2; exit 2; }
BASE_REF=develop
HISTORY_LIMIT=200
BRANCHES=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base) shift; [ "$#" -gt 0 ] || usage; BASE_REF=$1 ;;
    --history-limit)
      shift; [ "$#" -gt 0 ] || usage
      case "$1" in ''|*[!0-9]*) usage ;; esac
      [ "$1" -gt 0 ] && [ "$1" -le 100000 ] || usage
      HISTORY_LIMIT=$1 ;;
    -*) usage ;;
    *) BRANCHES="$BRANCHES $1" ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail 'not inside a Git worktree'
BASE=$(git rev-parse --verify --quiet --end-of-options "$BASE_REF^{commit}") || fail "base ref not found: $BASE_REF"
BASE_NAME=$(git rev-parse --symbolic-full-name --verify --end-of-options "$BASE_REF") || fail 'cannot resolve base name'
CURRENT_BRANCH=$(git symbolic-ref --quiet HEAD || :)
SHALLOW=$(git rev-parse --is-shallow-repository) || fail 'cannot inspect shallow state'
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
if [ -z "$BRANCHES" ]; then
  BRANCHES=$(git for-each-ref --format='%(refname:short)' \
    'refs/heads/feature/*' 'refs/heads/fix/*' 'refs/heads/chore/*' 'refs/heads/hotfix/*') || fail 'cannot list branches'
fi
emit() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; }

# An absent path is empty; otherwise include mode, object type, and object id.
entry_at() {
  entry=$(git ls-tree "$1" -- ":(literal)$2") || fail 'cannot read tree'
  printf '%s\n' "$entry" | cut -f1
}

# Search only post-fork history. A failed, shallow, or bounded search is unknown.
history_had() {
  history_ref=$1 history_path=$2 history_want=$3
  [ "$SHALLOW" = false ] || { printf unknown; return; }
  git rev-list --full-history --max-count="$((HISTORY_LIMIT + 1))" \
    "$merge_base..$history_ref" -- ":(literal)$history_path" > "$WORK/commits" || { printf unknown; return; }
  [ "$(wc -l < "$WORK/commits")" -le "$HISTORY_LIMIT" ] || { printf unknown; return; }
  while IFS= read -r commit; do
    historical=$(entry_at "$commit" "$history_path") || { printf unknown; return; }
    if [ "$historical" = "$history_want" ]; then printf found; return; fi
  done < "$WORK/commits"
  printf absent
}

# Git branch names cannot contain whitespace or glob characters.
for branch in $BRANCHES; do
  name=${branch#refs/heads/}
  ref=refs/heads/$name
  if [ "$name" = main ] || [ "$name" = develop ] || [ "$ref" = "$CURRENT_BRANCH" ] || [ "$ref" = "$BASE_NAME" ]; then
    emit protected "$branch" 'base, main, develop, or the current branch'; continue
  fi
  tip=$(git rev-parse --verify --quiet "$ref^{commit}") || { emit undecidable "$branch" 'local branch not found'; continue; }
  git merge-base --all "$BASE" "$tip" > "$WORK/bases" || { emit undecidable "$branch" 'no merge base'; continue; }
  [ "$(wc -l < "$WORK/bases")" -eq 1 ] || { emit undecidable "$branch" 'multiple merge bases'; continue; }
  merge_base=$(cat "$WORK/bases")
  # Force quoting independent of user config. Quoted/control/non-ASCII filenames
  # are deliberately unsupported, rather than decoded incorrectly as absent paths.
  git -c core.quotePath=true diff --no-ext-diff --ignore-submodules=none --no-renames --name-only "$merge_base" "$tip" > "$WORK/paths" || fail 'cannot enumerate changed paths'
  if LC_ALL=C grep '^"' "$WORK/paths" >/dev/null; then
    emit undecidable "$branch" 'a changed path needs Git quoting; this classifier does not decode quoted paths'; continue
  fi
  changed_total=0 missing_total=0 unclear_total=0
  missing_first='' unclear_reason=''
  while IFS= read -r path; do
    changed_total=$((changed_total + 1))
    task_entry=$(entry_at "$tip" "$path") || fail 'cannot read task tree'
    base_entry=$(entry_at "$BASE" "$path") || fail 'cannot read base tree'
    [ "$task_entry" != "$base_entry" ] || continue
    fork_entry=$(entry_at "$merge_base" "$path") || fail 'cannot read merge-base tree'
    held=$(history_had "$BASE" "$path" "$task_entry")
    if [ "$held" = absent ] && [ "$base_entry" = "$fork_entry" ]; then
      missing_total=$((missing_total + 1))
      [ -n "$missing_first" ] || missing_first=$path
    elif [ "$held" = absent ] && [ "$(history_had "$tip" "$path" "$base_entry")" = found ]; then
      missing_total=$((missing_total + 1))
      [ -n "$missing_first" ] || missing_first=$path
    else
      unclear_total=$((unclear_total + 1))
      [ -n "$unclear_reason" ] || unclear_reason="$path differs: history cannot prove the task still stands (divergence, later edit/revert, or incomplete history)"
    fi
  done < "$WORK/paths"
  if [ "$missing_total" -gt 0 ]; then
    detail="$missing_total of $changed_total changed path(s) have unincorporated content, starting with $missing_first"
    [ "$unclear_total" -eq 0 ] || detail="$detail; $unclear_total further path(s) undecidable"
    emit unincorporated "$branch" "$detail"
  elif [ "$unclear_total" -gt 0 ]; then
    emit undecidable "$branch" "$unclear_reason"
  else
    emit incorporated "$branch" "$changed_total changed path(s) all match $BASE_REF (content, type, and mode)"
  fi
done
