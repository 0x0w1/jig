---
name: github-release
description: Use when releasing this repository with a concrete vX.Y.Z version, creating release/vX.Y.Z from develop, opening or merging a patch/minor/major release PR to main, and relying on release-drafter publication.
---

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
