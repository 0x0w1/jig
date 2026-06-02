# Codex Rules

Use these repo-scoped Codex skills:

- Repository setup/sync: `github-sync` from `.agents/skills/github-sync/SKILL.md`.
- Release: `github-release` from `.agents/skills/github-release/SKILL.md`.
- Ordinary implementation tasks targeting `develop`: `develop-task-flow` from `.agents/skills/develop-task-flow/SKILL.md`.

## Repository Model

- `main` and `develop` are protected branches.
- Work branches target `develop`: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Release branches target `main`: `release/vX.Y.Z`.
- Standard labels are exactly `patch`, `minor`, `major`, `enhancement`, `fix`, `chore`.
- Release publication is handled by release-drafter on `main`.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not delete labels without explicit user confirmation.
- Do not overwrite user-modified files without explicit user confirmation.
- Keep repository skills under `.agents/skills`.
- Do not create `.codex`, `.claude/skills`, or unrequested AI skill directories inside this repository.
- Do not manually create release tags or GitHub releases when release-drafter is configured.
- For ordinary implementation tasks, create a `feature/*`, `fix/*`, or `chore/*` branch from `origin/develop`, run tests, open a PR to `develop`, and merge it automatically only when checks pass, the PR is mergeable, and branch protection allows it.
- For release PRs, do not merge unless the user explicitly asks for merge execution and checks/protection allow it.
- Preserve unrelated user changes.

## Develop Task Rules

- Use `develop-task-flow` for normal code/config/docs work.
- Create task branches from `origin/develop`.
- Use `feature/<slug>`, `fix/<slug>`, or `chore/<slug>`.
- Target PRs to `develop`.
- Run relevant tests before pushing or merging.
- Merge into `develop` automatically only for the current task PR, only after tests/checks pass, and never by direct push.

## Release Rules

- Release requests must use `vX.Y.Z`.
- Create `release/vX.Y.Z` from `origin/develop`.
- Open the release PR with base `main`.
- Treat release PRs as version upgrades, not chores.
- Title release PRs as `<patch|minor|major>: release vX.Y.Z`.
- Use a merge commit for `release/*` into `main`; do not require linear history on `main`.
- Apply one version label: `patch`, `minor`, or `major`.
- Do not apply `chore`, `enhancement`, or `fix` to release PRs.
- Let release-drafter publish the release and tag after `main` receives the release merge.

## Reporting

When doing release work, report:

- Current repo and branch
- Created or reused branches
- Created, existing, merged, or pending PRs
- Release/tag status
- Blocked commands and reasons
