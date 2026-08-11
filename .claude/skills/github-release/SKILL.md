---
name: github-release
description: Use when releasing this repository from the CLI by promoting develop to main with a fast-forward push, computing the next patch/minor/major version from the latest tag, and publishing a GitHub release with agent-written notes. No release PR, no release-drafter.
---

<!-- spai:owned skill=github-release -->

# GitHub Release

Use this repository skill for release execution.

## Release Model

- A release promotes the current `origin/develop` to `main` with a fast-forward push: `git push origin develop:main`. There is no release PR and no `release/*` branch.
- `develop` must already contain every intended release change, squash-merged through `develop-task-flow`.
- The next version is computed from the latest `vX.Y.Z` tag using the requested bump type:
  - `patch`: `vX.Y.Z` → `vX.Y.(Z+1)` (default when no type is given)
  - `minor`: `vX.Y.Z` → `vX.(Y+1).0`
  - `major`: `vX.Y.Z` → `v(X+1).0.0`
  - An explicit `vX.Y.Z` from the user overrides the computed version.
- Bump type guidance:
  - `patch`: bug fixes, wording, and internal changes; re-running the installer is enough.
  - `minor`: new or improved skills and installer features that stay backward compatible; re-running the installer is enough.
  - `major`: release flow or repository policy changes that require repository-side migration in installed projects (branch protection, file or label cleanup, branch model changes). These releases must carry a `### Migration` section in the notes.
- The release tag and GitHub release are created from the CLI with `git tag` and `gh release create`.
- Release notes are written by the agent from the commits in `<previous tag>..<new tag>`, categorized by conventional commit prefix.

## Safety Rules

- Do not force push.
- If `git push origin develop:main` would not fast-forward, stop and report that `main` has commits `develop` lacks; never resolve this by force-pushing.
- Do not release while the worktree has uncommitted changes to tracked files.
- Do not create a tag that already exists locally or on `origin`.
- Do not release while local `develop` differs from `origin/develop`.
- Do not delete branches.
- The release must only promote already-merged `develop` state; complete pending work through `develop-task-flow` first.
- Show the release note draft to the user before publishing, unless the user already asked for the release to be executed end to end.
- Preserve unrelated user changes.

## Develop-First Gate

- If the release request includes unfinished implementation, config, docs, generated `dist`, or workflow changes, stop release execution.
- Complete those changes first with `develop-task-flow`: create a `feature/*`, `fix/*`, or `chore/*` branch from `origin/develop`, squash-merge it into `develop`, and push `develop`.
- Resume release only after `origin/develop` contains every intended change.
- If the user has not explicitly asked to release, stop after `develop` is pushed.

## Release Procedure

1. Inspect state:
   - `git status --short --branch`
   - `git fetch origin --prune`
   - verify local `develop` matches `origin/develop`
2. Determine the previous version: latest `vX.Y.Z` tag reachable from `origin/main` (`git describe --tags --abbrev=0 origin/main`).
3. Compute the new version from the requested bump type, or validate the explicit version. The version must match `^v[0-9]+\.[0-9]+\.[0-9]+$` and must not exist as a tag or release.
4. Verify `origin/develop` already contains every intended release change. If not, stop and run the Develop-First Gate.
5. Run repository validation when available (for this repository: `sh scripts/validate-dist.sh`).
6. Promote: `git push origin develop:main`. This must fast-forward; if rejected, stop and report.
7. Tag the released commit: `git tag <version> <develop sha>` then `git push origin <version>`.
8. Compose the release notes from `git log <previous>..<version> --no-merges`:
   - `## Changes` with these sections in order, each only when it has items, separated by horizontal rules:
     - `### 🚀 Enhancements` for `feat:` commits
     - `### 🐛 Fixes` for `fix:` commits
     - `### 🧰 Chores` for all other commits
   - One `- <commit subject without type prefix>` line per commit.
   - `### Summary`: Korean user-perspective bullet items the agent writes from the commit subjects and bodies, release-note ready, with technical terms in backticks.
   - `### Migration`: only when installed projects must take repository-side action beyond re-running the installer (protection changes, file or label cleanup, branch model changes). List the exact steps; the `spai-update` skill surfaces this section to users.
9. Publish: `gh release create <version> --title "<version> 🌈" --notes-file <draft file>`.
10. Verify the release and tag exist (`gh release view <version>`).

## Final Report

Keep reports short and include:

- Current repo and branch
- Previous and new version
- `develop` to `main` promotion result
- Tag and release status
- Release note summary
- Commands that could not run and why
- User next actions, if any
