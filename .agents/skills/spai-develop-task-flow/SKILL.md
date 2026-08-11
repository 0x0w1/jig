---
name: spai-develop-task-flow
description: Use for ordinary implementation tasks in this repository that should start from develop, create a feature/fix/chore branch, complete changes and tests, squash-merge the branch back into develop locally, and push develop. No pull requests.
---

# Develop Task Flow

Use this repository skill for normal development work requested by the user.

## Branch Model

- Start from `origin/develop`.
- Create one task branch:
  - `feature/<slug>` for user-visible features or enhancements.
  - `fix/<slug>` for bug, regression, or security fixes.
  - `chore/<slug>` for tooling, dependencies, refactors, docs, or automation setup.
- Finish the task by squash-merging the branch into `develop` locally and pushing `develop`. There are no pull requests.
- Ordinary code, config, documentation, generated `dist`, workflow, and installer changes must follow this flow before any release can include them.
- A release promotes `develop` to `main` with a fast-forward push; it is not a task. Use `github-release` for releases.

## Commit Message Rules

The squash commit on `develop` is the release-note source. Every squash commit must follow this format:

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
5. Commit on the task branch, squash-merge into `develop`, push `develop`.
6. Report results and any remaining action.

## Documentation Rules

- If a change affects installation behavior, user-facing workflows, supported targets, repository policy, CLI output, or public project usage, update `README.md` in the same task.
- If the change is broad or would make `README.md` too dense, create or update a focused Markdown file under top-level `docs/` and add a link near the top of `README.md`.
- If top-level `docs/` already exists, reuse it instead of creating another documentation directory.
- This repository is itself managed by the SPAI setup skills, and its documentation, skills, and installer are distributed publicly. Every example must stay generic: use placeholders such as `your-account`, `your@email.com`, and `/absolute/path/to/<name>`. Never include local machine paths, personal identifiers, or examples taken from local or other projects.
- During validation, check that the README/docs update explains the new behavior clearly.

## Safety Rules

- Do not force push.
- Do not delete branches without explicit user confirmation; merged task branches may remain.
- Do not push directly to `main`; `main` only updates through `github-release`.
- Do not modify or revert unrelated user changes.
- Do not overwrite files with different content without explicit confirmation.
- Do not merge into `develop` if tests fail or the squash commit would include changes outside the current task.
- Do not use this skill for release execution; use `github-release`.
- If the user has not explicitly asked for a release, stop after `develop` is pushed.

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
9. Update `develop`: `git checkout develop` then `git pull --ff-only origin develop`.
10. Squash-merge: `git merge --squash <prefix>/<slug>`, then commit once following the Commit Message Rules.
11. Push `develop` without force.
12. Leave the task branch in place; offer cleanup only as an optional next action.

## Final Report

Keep reports short and include:

- Branch created or reused
- Files changed
- Tests run and result
- README/docs update status
- Squash commit subject pushed to `develop`
- Commands that could not run and why
- User next actions, if any
