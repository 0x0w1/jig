---
name: github-sync
description: "Use when synchronizing this repository's GitHub setup: main/develop branch existence and branch protection for the CLI release flow. Do not use for creating a release."
---

# GitHub Sync

Use this repository skill only for setup and synchronization of GitHub repository settings.

## Scope

- Branches: `main`, `develop`.
- Branch protection for `main` and `develop`: direct pushes allowed, force pushes and deletion blocked.
- No release-drafter files, no pull request template, no label sync; the release flow is CLI-driven (`github-release`) and does not use pull requests.
- Sync is convergent and idempotent: one run aligns the repository with the current model even when several SPAI versions were skipped. `spai-update` runs it after updating installed files.

## Phase Rules

For broad sync work, split into phases:

1. Inspect repository, working tree, remotes, and `gh` access.
2. Verify or create `develop` from `main`.
3. Apply branch protection.
4. Validate and report.

If a phase is blocked by permission, missing auth, unsupported repository plan, or required confirmation, complete safe earlier phases and report the remaining work.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not delete labels without explicit confirmation.
- Do not create `.codex`, `.claude/skills`, or unrequested AI skill directories inside this repository.
- Keep repository skills under `.agents/skills`.
- Do not create releases or tags during sync.
- Do not rename the default branch or change the remote default branch without explicit confirmation.
- Preserve unrelated user changes.

## Procedure

1. Confirm the current directory is a git repository.
2. Check `git status --short --branch`.
3. Run `gh repo view` and `gh auth status`. If GitHub CLI is unavailable, unauthenticated, or lacks permission, report the remaining GitHub steps.
4. Confirm `main` exists locally and remotely when possible.
5. Confirm `develop` exists locally and remotely when possible. If missing, create it from `main` and push without force.
6. Protect `main` and `develop` with the same policy:
   - no required pull request reviews
   - no required status checks
   - force pushes disabled
   - deletion disabled
7. If legacy release-drafter files exist (`.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`), report them as removal candidates; remove them only with explicit confirmation.

## Final Report

Keep reports short and include:

- Branches created or already present
- Branch protection status
- Legacy release-drafter files found, if any
- Commands that could not run and why
- User next actions, if any
