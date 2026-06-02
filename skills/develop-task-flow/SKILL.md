---
name: develop-task-flow
description: Use for ordinary implementation tasks in this repository that should start from develop, create a feature/fix/chore branch, complete changes and tests, push the branch, open a PR to develop, and merge it into develop when safe and allowed.
---

# Develop Task Flow

Use this repository skill for normal development work requested by the user.

## Branch Model

- Start from `origin/develop`.
- Create one task branch:
  - `feature/<slug>` for user-visible features or enhancements.
  - `fix/<slug>` for bug, regression, or security fixes.
  - `chore/<slug>` for tooling, dependencies, refactors, docs, or release automation setup.
- Target `develop`.

## Phase Rules

If the task is large, split it into phases:

1. Inspect repo, worktree, branch state, and available test commands.
2. Create or reuse the task branch from `origin/develop`.
3. Implement the requested change.
4. Run focused tests, then broader tests when practical.
5. Commit, push, open or reuse a PR to `develop`.
6. Merge to `develop` only when safe and allowed.
7. Report results and any remaining action.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not push directly to `develop`.
- Do not modify or revert unrelated user changes.
- Do not overwrite files with different content without explicit confirmation.
- Do not merge if tests fail, checks fail, conflicts exist, or branch protection blocks the merge.
- Do not merge a PR that includes changes outside the current task.
- Do not use this skill for `release/vX.Y.Z` work; use `github-release`.

## Procedure

1. Inspect:
   - `git status --short --branch`
   - `git fetch origin --prune`
   - `git branch --list --all`
   - available test scripts or project docs
2. Classify branch prefix:
   - `feature` for new behavior or user-visible enhancement.
   - `fix` for bug/security/regression correction.
   - `chore` for tooling, docs, refactor, config, dependency, or automation work.
3. Create a short kebab-case slug from the task.
4. Create or reuse `<prefix>/<slug>` from `origin/develop`.
5. Implement the task while preserving unrelated changes.
6. Run tests:
   - Always run the most relevant focused test command if one exists.
   - Run the broad project test command when practical.
   - If no tests exist, run syntax/config validation appropriate to changed files and report the gap.
7. Commit only the task changes with a conventional message matching the branch type.
8. Push the branch without force.
9. Open or reuse a PR with base `develop` and head `<prefix>/<slug>`.
10. Apply one work label when possible:
   - `enhancement` for feature branches.
   - `fix` for fix branches.
   - `chore` for chore branches.
11. Merge the PR into `develop` automatically only if all conditions are true:
   - The user request asked for this automatic develop flow or `AGENTS.md` requires it.
   - The PR is the one created or reused for the current task.
   - The local and remote branch contain only current-task changes.
   - Required tests and checks pass.
   - The PR is mergeable.
   - Branch protection allows the merge.
12. Use `gh pr merge --merge` for the develop PR when the merge is allowed. Do not squash unless the user explicitly asks.
13. If merge is blocked, leave the PR open and report the exact blocker.

## Final Report

Keep reports short and include:

- Branch created or reused
- Files changed
- Tests run and result
- PR created, reused, merged, or blocked
- Labels applied
- Commands that could not run and why
- User next actions, if any
