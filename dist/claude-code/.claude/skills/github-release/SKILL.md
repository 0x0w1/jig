---
name: github-release
description: Use when releasing this repository with a concrete vX.Y.Z version by opening or merging a patch/minor/major release PR from develop to main and relying on release-drafter publication.
---

# GitHub Release

Use this repository skill for release execution.

## Release Model

- A release promotes the current `origin/develop` to `main` through a single release PR.
- The release PR has base `main` and head `develop`; there is no `release/*` branch.
- `develop` must already contain every intended release change, merged by PR.
- The release PR merges to `main` with a merge commit; do not require linear history on `main`.
- Release PRs are version upgrade PRs, not chore PRs.
- Release PR titles use `<patch|minor|major>: release vX.Y.Z`.
- Release PRs carry exactly one version label: `patch`, `minor`, or `major`.
- Release-drafter publishes the release and tag after `main` receives the release merge.
- Release notes are collected from the `develop`-targeting task PRs in the release range, so every change must reach `develop` through a `feature/*`, `fix/*`, or `chore/*` PR to appear in the notes.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not manually create release tags or GitHub releases when release-drafter is configured.
- Do not merge PRs unless the user explicitly requested merge execution and branch protection/checks allow it.
- Do not push directly to `main` or `develop`.
- The release PR must only promote already-merged `develop` state; do not add ordinary code, config, documentation, generated `dist`, or workflow changes in the release PR.
- Do not open a release PR while `origin/develop` still lacks an intended change; complete it through a task PR first.
- Preserve unrelated user changes.

## Develop-First Gate

- If the release request includes unmerged implementation, config, docs, generated `dist`, or workflow changes, stop release execution.
- Complete those changes first with `develop-task-flow`: create a `feature/*`, `fix/*`, or `chore/*` branch from `origin/develop`, push it, open a PR to `develop`, and merge that PR when safe and allowed.
- Resume release only after `origin/develop` contains every intended change.
- If the user has not explicitly asked to release, stop at the `develop` PR merge and do not open a release PR to `main`.

## Release Procedure

Use this when the user asks to release a concrete version such as `v0.1.0`.

1. Validate the version string is exactly `vX.Y.Z`.
2. Inspect state:
   - `git status --short --branch`
   - `git fetch origin --prune`
   - local and remote `main` and `develop`
   - open release PRs from `develop` to `main`
   - existing tag or release for the version
3. Stop and report if the worktree has unrelated user changes that would be touched.
4. Confirm release-drafter files exist:
   - `.github/drafter-config.yaml`
   - `.github/workflows/drafter.yaml`
5. Verify `origin/develop` already contains every intended release change. If not, stop and run the Develop-First Gate.
6. Decide the version upgrade type from the user request or release intent:
   - patch release: `patch`
   - minor release: `minor`
   - major release: `major`
7. Open or reuse a PR with base `main`, head `develop`, and title `<patch|minor|major>: release vX.Y.Z`.
8. Apply exactly one version label: `patch`, `minor`, or `major`.
9. Do not apply `chore`, `enhancement`, or `fix` to the release PR.
10. Do not manually create a tag or release.
11. Merge the release PR only if the user explicitly asked for merge execution and checks/protection allow it. Use a merge commit.
12. After `main` updates, expect the workflow to publish the release and tag.

## Final Report

Keep reports short and include:

- Current repo and branch
- Release PR status (`develop` to `main`)
- Version label status
- Release/tag status
- Commands that could not run and why
- User next actions, if any
