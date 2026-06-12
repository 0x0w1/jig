---
name: github-release
description: Use when releasing this repository with a concrete vX.Y.Z version, creating release/vX.Y.Z from develop, opening or merging a patch/minor/major release PR to main, and relying on release-drafter publication.
---

# GitHub Release

Use this repository skill for release execution.

## Release Model

- Release branches target `main`: `release/vX.Y.Z`.
- Release branches are created from the current `origin/develop`.
- Release branches contain the already-merged `develop` state intended for release.
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
- Do not commit ordinary code, config, documentation, generated `dist`, or workflow changes directly on `release/*`.
- Do not recreate or push a merged/deleted `release/*` branch unless starting a new version release from the current `origin/develop`.
- Preserve unrelated user changes.

## Develop-First Gate

- If the release request includes unmerged implementation, config, docs, generated `dist`, or workflow changes, stop release execution.
- Complete those changes first with `develop-task-flow`: create a `feature/*`, `fix/*`, or `chore/*` branch from `origin/develop`, push it, open a PR to `develop`, and merge that PR when safe and allowed.
- Resume release only after `origin/develop` contains every intended change.
- If the user has not explicitly asked to release, stop at the `develop` PR merge and do not create a `release/*` branch.

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
5. Verify `origin/develop` already contains every intended release change. If not, stop and run the Develop-First Gate.
6. Create `release/vX.Y.Z` from the current `origin/develop`, unless it already exists and points at the same intended `develop` state.
7. Push `release/vX.Y.Z` without force.
8. Decide the version upgrade type from the user request or release intent:
   - patch release: `patch`
   - minor release: `minor`
   - major release: `major`
9. Open or reuse a PR with base `main`, head `release/vX.Y.Z`, and title `<patch|minor|major>: release vX.Y.Z`.
10. Apply exactly one version label: `patch`, `minor`, or `major`.
11. Do not apply `chore`, `enhancement`, or `fix` to the release PR.
12. Do not manually create a tag or release.
13. Merge the release PR only if the user explicitly asked for merge execution and checks/protection allow it. Use a merge commit.
14. After `main` updates, expect the workflow to publish the release and tag.

## Final Report

Keep reports short and include:

- Current repo and branch
- Release branch status
- Release PR status
- Version label status
- Release/tag status
- Commands that could not run and why
- User next actions, if any
