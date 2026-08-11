---
name: develop-task-flow
description: Use for ordinary implementation tasks in this repository that should start from develop, create a feature/fix/chore branch, complete changes and tests, push the branch, open a pull request to develop, and merge it with squash when checks allow. Team flow.
---

# Develop Task Flow

Use this repository skill for normal development work requested by the user.

## Branch Model

- Start from `origin/develop`.
- Create one task branch:
  - `feature/<slug>` for user-visible features or enhancements.
  - `fix/<slug>` for bug, regression, or security fixes.
  - `chore/<slug>` for tooling, dependencies, refactors, docs, or automation setup.
- Finish the task by pushing the branch and opening a pull request with base `develop`; merge it with **squash** when checks pass and branch protection allows. The squash commit subject must follow the Commit Message Rules.
- Ordinary code, config, documentation, generated `dist`, workflow, and installer changes must follow this flow before any release can include them.
- A release promotes `develop` to `main` with a fast-forward push; it is not a task. Use `github-release` for releases.

## Commit Message Rules

The squash commit on `develop` is the release-note source. Every squash merge must produce a commit in this format:

- Subject: `<type>: <concise user-facing summary>` with `<type>` one of `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`.
- Release note category mapping: `feat:` renders under `🚀 Enhancements`, `fix:` under `🐛 Fixes`, everything else under `🧰 Chores`.
- Body: Korean bullet items describing the change from the user's perspective, release-note ready.
- In body bullets, wrap useful technical terms in backticks, such as file paths, config keys, branch names, workflow names, command names, and env vars.

## Phase Rules

If the task is large, split it into phases:

1. Inspect repo, worktree, branch state, and available test commands.
2. Create or reuse the task branch from `origin/develop`.
3. Implement the requested change.
4. Run focused tests, then broader tests when practical.
5. Commit on the task branch, push it, open or reuse the pull request.
6. Merge with squash when safe and allowed.
7. Report results and any remaining action.

## Documentation Rules

- If a change affects installation behavior, user-facing workflows, supported targets, repository policy, CLI output, or public project usage, update `README.md` in the same task.
- If the change is broad or would make `README.md` too dense, create or update a focused Markdown file under top-level `docs/` and add a link near the top of `README.md`.
- If top-level `docs/` already exists, reuse it instead of creating another documentation directory.
- Keep every example generic: use placeholders such as `your-account`, `your@email.com`, and `/absolute/path/to/<name>`. Never include local machine paths, personal identifiers, or examples taken from local or other projects.
- During validation, check that the README/docs update explains the new behavior clearly.

## Safety Rules

- Do not force push.
- Do not delete branches without explicit user confirmation.
- Do not push directly to `develop`; every change reaches `develop` through a squash-merged pull request.
- Do not push directly to `main`; `main` only updates through `github-release`.
- Do not modify or revert unrelated user changes.
- Do not overwrite files with different content without explicit confirmation.
- Do not merge if tests fail, checks fail, conflicts exist, or branch protection blocks the merge.
- Do not merge a pull request that includes changes outside the current task.
- Do not use this skill for release execution; use `github-release`.
- If the user has not explicitly asked for a release, stop after the `develop` pull request is merged or left open with a blocker.

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
7. Apply the Documentation Rules before committing.
8. Commit only the task changes on the task branch.
9. Push the task branch without force.
10. Open or reuse a pull request with base `develop` and head `<prefix>/<slug>`. Write the PR body with:
    - `## Summary`: Korean, user-perspective, release-note-ready bullets with technical terms in backticks.
    - `## Details`: implementation, configuration, policy, and impact details.
    - `## Tests`: commands run and results.
11. Merge the pull request with `gh pr merge --squash` only if all conditions are true:
    - The user request asked for this flow's automatic merge or repository rules require it.
    - The PR is the one created or reused for the current task.
    - Required tests and checks pass and the PR is mergeable.
    - Branch protection allows the merge.
    - The squash commit message follows the Commit Message Rules.
12. If the merge is blocked, leave the PR open and report the exact blocker.

## Final Report

Keep reports short and include:

- Branch created or reused
- Files changed
- Tests run and result
- README/docs update status
- Pull request created, reused, merged, or blocked
- Squash commit subject merged into `develop`
- Commands that could not run and why
- User next actions, if any
