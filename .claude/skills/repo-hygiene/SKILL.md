---
name: repo-hygiene
description: Use to audit and clean the debris a long-running jig repository accumulates: task branches whose work already shipped, branches from retired flows, stale remote-tracking refs, tag and release mismatches, an uncommitted rubric, and installer .bak leftovers. Reports first; deletes only what the user confirms.
---

# Repo Hygiene

Use this repository skill to find and clear the debris that builds up in a repository worked through jig. It audits first and always reports; it removes only what the user names.

This is the repository's own housekeeping. For the state of the jig **installation**, use `jig-doctor`, which is read-only and never deletes.

## Why Merged Branches Look Unmerged

`develop-task-flow` finishes with `git merge --squash`, so the task branch tip never becomes an ancestor of `develop`. Git therefore reports every finished branch as unmerged:

```bash
git branch --merged develop     # finds almost nothing
git branch --no-merged develop  # lists work that shipped months ago
```

**Never decide a branch is safe to delete with `--merged`.** Under a squash flow it answers a different question than the one being asked.

A plain diff does not answer it either, in either spelling:

| Command | What it compares | Why it misjudges |
|---|---|---|
| `git diff develop...<branch>` | merge base against the branch | still shows the branch's own contribution after a squash merge, so finished work reads as unfinished |
| `git diff develop..<branch>` | the two tips | any later unrelated commit on `develop` makes a finished branch read as unfinished |

The supported question is: **do all paths changed by the task relative to its unique merge base match the base's current content, type, and mode?** Unrelated paths on `develop` do not matter. Use the read-only classifier relative to this skill directory:

```bash
sh scripts/classify-branches.sh [--base develop] [--history-limit 200] [<local-branch>...]
```

It prints `<status>\t<branch>\t<detail>` for each branch:

| Status | Meaning |
|---|---|
| `incorporated` | changed paths match now |
| `unincorporated` | definite outstanding content |
| `undecidable` | insufficient evidence |
| `protected` | never a deletion candidate |

Only `incorporated` may be offered for explicitly approved deletion. This is content equivalence, not proof of a particular merge commit. It includes an empty task diff. Additions, deletions, and mode/type changes are compared; renames are a deletion plus an addition, so copying only the destination is insufficient.

For differing paths the script checks bounded history after the merge base:

- The base remains at the pre-task version and never held the task version → `unincorporated`.
- The base holds an earlier task version, and never held its latest version → `unincorporated`.
- Historical equality followed by any differing content, including extensions, full/partial reverts, and conflict resolution → `undecidable`. A historical blob match cannot prove the task still stands.
- Independent edits, truncated/shallow history, or other insufficient evidence → `undecidable`.

One definite outstanding path makes the branch `unincorporated`; details also count any undecidable paths. Neither result permits offering deletion.

Limits: quoted filenames (including control characters and non-ASCII names), missing or multiple merge bases, and nonlocal branch arguments are `undecidable`. Git failures exit nonzero or yield `undecidable`; never interpret failure as an empty diff. History is bounded to 200 commits per differing path by default. The script reads committed trees only, not uncommitted work, and never deletes anything.

## Checks

Each check reports on its own. A repository that fails none is a normal outcome, not a defect.

| Check | What it looks for | Signal |
|---|---|---|
| Shipped task branches | `feature/*`, `fix/*`, `chore/*`, `hotfix/*` the classifier calls `incorporated` | safe to delete |
| Unfinished task branches | the same prefixes reported `unincorporated` | report only, never offer |
| Undecidable branches | the same prefixes reported `undecidable`, with the reason | report only, never offer |
| Retired-flow branches | branches from a model this repository no longer uses, such as `release/*` | report with the reason, offer |
| Stale remote-tracking refs | `origin/*` refs whose upstream branch is gone | `git remote prune origin` |
| Tag and release mismatch | `vX.Y.Z` tags with no GitHub release, or releases with no tag | report only |
| Rubric reachability | the resolved rubric file is untracked or has uncommitted changes | report; it does not reach clones or CI |
| Installer leftovers | `.bak` files the installer wrote, and payload files no longer in the manifest | report; deletion needs confirmation |
| Unfinished hotfix | `git merge-base --is-ancestor origin/main origin/develop` fails | report loudly; the next release is blocked until `hotfix-flow` step 8 runs |

## Safety Rules

- Never delete anything the user has not explicitly named in this run. A list is not consent.
- Never touch `main`, `develop`, or the current branch, even when a check matches them.
- Offer a branch for deletion only when the classifier reported it `incorporated`. `unincorporated`, `undecidable`, and `protected` are never offered, and an undecidable branch is never presented as probably safe.
- Never re-classify a branch by eye when the script reports `undecidable`. Report the reason it gave and let the user decide.
- Never delete a remote branch. This skill works on the local clone; `git push origin --delete` is out of scope.
- Never delete or move a tag or a GitHub release. Mismatches are reported for a human to settle.
- Never touch `.jig/`. It is project-owned; only `version-rubric` writes the rubric file.
- Do not force push, and do not run any command that rewrites history.
- Do not modify tracked files. The only writes are deletions the user confirmed.
- Report the exact command for anything that cannot run, rather than approximating it.
- Preserve unrelated user changes.

## Procedure

1. Inspect:
   - `git status --short --branch`
   - `git fetch origin --prune --tags`
   - `git branch --list`
2. Classify every local task branch by content, not by merge state, by running `scripts/classify-branches.sh` relative to this skill directory. Read the status column; do not re-derive it.
   - Run it with no branch arguments to cover every local `feature/*`, `fix/*`, `chore/*`, and `hotfix/*`.
   - Group the output by status and carry each `undecidable` detail into the report verbatim.
   - If the script cannot run, say so and classify nothing. Reporting "unknown" is correct; guessing from `git branch --merged` is not.
3. List branches belonging to retired flows and say which model they came from.
4. Report stale remote-tracking refs. `git fetch --prune` in step 1 already cleared them; name what it removed.
5. Compare tags with releases, resolving the GitHub profile the way `github-release` does before any `gh` command. Skip this check with a one-line note when `gh` is unavailable.
6. Check that the resolved rubric file is tracked and committed.
7. Check the release invariant: `git merge-base --is-ancestor origin/main origin/develop`. A failure means a hotfix landed on `main` and never returned to `develop`, so `github-release` cannot promote until `git merge main` runs. Report it first; it blocks more than anything else on this list.
8. Find `.bak` leftovers and payload files no longer listed in the manifest.
9. Present the findings grouped by check, with counts and the exact deletion command for each group.
10. Ask which exact candidates or listed groups to clear unless already explicitly approved. Before deletion, re-run the classifier for those branches, recheck their tips and protected/current branches, and exclude branches checked out in any worktree (`git worktree list --porcelain`). If a tip changed since approval, report it for a new decision. Delete only approved, still-incorporated candidates, echoing what was removed. Retired-flow membership alone never permits branch deletion.
11. Report.

## Final Report

Write the report in the language the repository already uses.

```md
## Repo Hygiene

- Branches: <n> shipped, <n> unfinished, <n> undecidable, <n> from retired flows
- Undecidable branches and why: <list or none>
- Deleted: none | <list>
- Remote-tracking refs pruned: <n>
- Tags without releases: <list or none>
- Rubric: committed | untracked | uncommitted changes
- Release invariant: ok | **main is ahead of develop, next release blocked**
- Leftovers: <list or none>
- Skipped checks and why: <list or none>
- Next: none | <action>
```
