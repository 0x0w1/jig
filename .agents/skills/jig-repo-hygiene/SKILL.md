---
name: jig-repo-hygiene
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

Ask whether the branch's content is already in `develop` instead:

```bash
git diff --quiet develop...<branch>
```

An empty diff means everything on that branch is already reachable from `develop`, whatever the SHAs look like. That is the safe signal. A non-empty diff means the branch still holds something, so it is reported as unfinished and never offered for deletion.

## Checks

Each check reports on its own. A repository that fails none is a normal outcome, not a defect.

| Check | What it looks for | Signal |
|---|---|---|
| Shipped task branches | `feature/*`, `fix/*`, `chore/*`, `hotfix/*` whose diff against `develop` is empty | safe to delete |
| Unfinished task branches | the same prefixes with a non-empty diff | report only, never offer |
| Retired-flow branches | branches from a model this repository no longer uses, such as `release/*` | report with the reason, offer |
| Stale remote-tracking refs | `origin/*` refs whose upstream branch is gone | `git remote prune origin` |
| Tag and release mismatch | `vX.Y.Z` tags with no GitHub release, or releases with no tag | report only |
| Rubric reachability | the resolved rubric file is untracked or has uncommitted changes | report; it does not reach clones or CI |
| Installer leftovers | `.bak` files the installer wrote, and payload files no longer in the manifest | report; deletion needs confirmation |

## Safety Rules

- Never delete anything the user has not explicitly named in this run. A list is not consent.
- Never touch `main`, `develop`, or the current branch, even when a check matches them.
- Never delete a branch whose diff against `develop` is non-empty, and never offer one.
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
2. Classify every local task branch by content, not by merge state:
   - for each `feature/*`, `fix/*`, `chore/*`, `hotfix/*`: `git diff --quiet develop...<branch>`
   - empty diff → shipped; non-empty → unfinished
3. List branches belonging to retired flows and say which model they came from.
4. Report stale remote-tracking refs. `git fetch --prune` in step 1 already cleared them; name what it removed.
5. Compare tags with releases, resolving the GitHub profile the way `github-release` does before any `gh` command. Skip this check with a one-line note when `gh` is unavailable.
6. Check that the resolved rubric file is tracked and committed.
7. Find `.bak` leftovers and payload files no longer listed in the manifest.
8. Present the findings grouped by check, with counts and the exact deletion command for each group.
9. Ask which groups to clear. Delete only those, one group at a time, echoing what was removed.
10. Report.

## Final Report

Write the report in the language the repository already uses.

```md
## Repo Hygiene

- Branches: <n> shipped, <n> unfinished, <n> from retired flows
- Deleted: none | <list>
- Remote-tracking refs pruned: <n>
- Tags without releases: <list or none>
- Rubric: committed | untracked | uncommitted changes
- Leftovers: <list or none>
- Skipped checks and why: <list or none>
- Next: none | <action>
```
