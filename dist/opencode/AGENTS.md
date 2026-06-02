# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release/vX.Y.Z execution from develop to main.
- `develop-task-flow`: normal development tasks from develop through a PR back to develop.


## github-sync


# GitHub Sync

Use this repository skill only for setup and synchronization of GitHub repository settings.

## Scope

- Managed files:
  - `.github/drafter-config.yaml`
  - `.github/workflows/drafter.yaml`
- Branches: `main`, `develop`.
- Standard labels: `patch`, `minor`, `major`, `enhancement`, `fix`, `chore`.
- Branch protection for `main` and `develop`.
- Repository general setting: Automatically delete head branches.

## Phase Rules

For broad sync work, split into phases:

1. Inspect repository, working tree, remotes, and `gh` access.
2. Apply or verify managed files.
3. Verify or create `develop` from `main`.
4. Sync labels.
5. Sync repository general settings.
6. Apply branch protection.
7. Validate and report.

If a phase is blocked by permission, missing auth, unsupported repository plan, or required confirmation, complete safe earlier phases and report the remaining work.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not delete labels without explicit confirmation.
- Do not overwrite files with different content without explicit confirmation. After confirmation, preserve the previous file as `*.bak`.
- Do not create `.codex`, `.claude/skills`, or unrequested AI skill directories inside this repository.
- Keep repository skills under `.agents/skills`.
- Do not create releases or tags during sync.
- Do not merge PRs during sync.
- Do not manually delete branches while enabling automatic head branch deletion.
- Do not rename the default branch or change the remote default branch without explicit confirmation.
- Preserve unrelated user changes.

## Procedure

1. Confirm the current directory is a git repository.
2. Check `git status --short --branch`.
3. Run `gh repo view` and `gh auth status`. If GitHub CLI is unavailable, unauthenticated, or lacks permission, apply local files only and report remaining GitHub steps.
4. Ensure `.github/workflows` exists.
5. Apply the managed files. If an existing managed file differs, ask before overwriting and save a `*.bak` after confirmation.
6. Confirm `main` exists locally and remotely when possible.
7. Confirm `develop` exists locally and remotely when possible. If missing, create it from `main` and push without force.
8. Ensure these labels exist with exact values:

| Label | Color | Description |
|---|---|---|
| `patch` | `0E8A16` | 하위 호환 버그 수정 또는 내부 변경 |
| `minor` | `1D76DB` | 하위 호환 신규 기능 |
| `major` | `B60205` | 호환성을 깨는(breaking) 변경 |
| `enhancement` | `A2EEEF` | 사용자에게 보이는 신규 기능 또는 개선 |
| `fix` | `FBCA04` | 버그, 회귀(regression), 또는 보안 수정 |
| `chore` | `CFD3D7` | 의존성, 툴링, 리팩터링, 문서 |

9. Before deleting labels outside the standard six, show the exact deletion list and ask for confirmation.
10. Enable the repository General setting `Automatically delete head branches` when GitHub CLI permissions allow it.
11. Protect `main`: PR required, no linear-history requirement, force-push disabled, deletion disabled, conversation resolution required. Require `update_release_draft` only after the workflow is already present on `main`.
12. Protect `develop`: PR required, force-push disabled, deletion disabled, conversation resolution required.

## Final Report

Keep reports short and include:

- Applied files
- Skipped or backed up files
- Branches created or already present
- Labels created, updated, skipped, or waiting for confirmation
- Repository general setting status
- Branch protection status
- Commands that could not run and why
- User next actions, if any

## github-release


# GitHub Release

Use this repository skill for release execution.

## Release Model

- Release branches target `main`: `release/vX.Y.Z`.
- Release branches are created from `origin/develop`.
- `release/*` merges to `main` with a merge commit.
- Release PRs are version upgrade PRs, not chore PRs.
- Release PR titles use `<patch|minor|major>: release vX.Y.Z`.
- Release PRs carry exactly one version label: `patch`, `minor`, or `major`.
- Release-drafter publishes the release and tag after `main` receives the release merge.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not manually create release tags or GitHub releases when release-drafter is configured.
- Do not merge PRs unless the user explicitly requested merge execution and branch protection/checks allow it.
- Do not push directly to `main` or `develop`.
- Preserve unrelated user changes.

## Release Procedure

Use this when the user asks to release a concrete version such as `v0.1.0`.

1. Validate the version string is exactly `vX.Y.Z`.
2. Inspect state:
   - `git status --short --branch`
   - `git fetch origin --prune`
   - local and remote `main` and `develop`
   - existing `release/vX.Y.Z` branch
   - open release PRs
   - existing tag or release for the version
3. Stop and report if the worktree has unrelated user changes that would be touched.
4. Confirm release-drafter files exist:
   - `.github/drafter-config.yaml`
   - `.github/workflows/drafter.yaml`
5. Create `release/vX.Y.Z` from `origin/develop`, unless it already exists.
6. Push `release/vX.Y.Z` without force.
7. Decide the version upgrade type from the user request or release intent:
   - patch release: `patch`
   - minor release: `minor`
   - major release: `major`
8. Open or reuse a PR with base `main`, head `release/vX.Y.Z`, and title `<patch|minor|major>: release vX.Y.Z`.
9. Apply exactly one version label: `patch`, `minor`, or `major`.
10. Do not apply `chore`, `enhancement`, or `fix` to the release PR.
11. Do not manually create a tag or release.
12. Merge the release PR only if the user explicitly asked for merge execution and checks/protection allow it. Use a merge commit.
13. After `main` updates, expect the workflow to publish the release and tag.

## Final Report

Keep reports short and include:

- Current repo and branch
- Release branch status
- Release PR status
- Version label status
- Release/tag status
- Commands that could not run and why
- User next actions, if any

## develop-task-flow


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

## Documentation Rules

- If a change affects installation behavior, user-facing workflows, supported targets, repository policy, CLI output, or public project usage, update `README.md` in the same task.
- If the change is broad or would make `README.md` too dense, create or update a focused Markdown file under top-level `docs/` and add a link near the top of `README.md`.
- If top-level `docs/` already exists, reuse it instead of creating another documentation directory.
- During validation, check that the README/docs update explains the new behavior clearly.

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
7. Apply the Documentation Rules before committing.
8. Commit only the task changes with a conventional message matching the branch type.
9. Push the branch without force.
10. Open or reuse a PR with base `develop` and head `<prefix>/<slug>`.
11. Apply one work label when possible:
   - `enhancement` for feature branches.
   - `fix` for fix branches.
   - `chore` for chore branches.
12. Merge the PR into `develop` automatically only if all conditions are true:
   - The user request asked for this automatic develop flow or `AGENTS.md` requires it.
   - The PR is the one created or reused for the current task.
   - The local and remote branch contain only current-task changes.
   - Required tests and checks pass.
   - The PR is mergeable.
   - Branch protection allows the merge.
13. Use `gh pr merge --merge` for the develop PR when the merge is allowed. Do not squash unless the user explicitly asks.
14. If merge is blocked, leave the PR open and report the exact blocker.

## Final Report

Keep reports short and include:

- Branch created or reused
- Files changed
- Tests run and result
- README/docs update status
- PR created, reused, merged, or blocked
- Labels applied
- Commands that could not run and why
- User next actions, if any

<!-- spai:end github-release-setup -->
