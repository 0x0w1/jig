# Claude Code Rules

Use these repo-scoped Claude Code skills:

- Repository setup/sync: `github-sync` from `.claude/skills/github-sync/SKILL.md`.
- Release: `github-release` from `.claude/skills/github-release/SKILL.md`.
- Ordinary implementation tasks targeting `develop`: `develop-task-flow` from `.claude/skills/develop-task-flow/SKILL.md`.
- README writing/updating: `readme` from `.claude/skills/readme/SKILL.md`.
- SPAI project installation and GitHub profile setup: `project-setup` from `.claude/skills/project-setup/SKILL.md`.
- SPAI installation updates: `spai-update` from `.claude/skills/spai-update/SKILL.md`.
- SPAI installation diagnostics: `spai-doctor` from `.claude/skills/spai-doctor/SKILL.md`.

## Repository Model

- `main` and `develop` are protected against force pushes and deletion; direct pushes are allowed.
- Work branches start from `origin/develop`: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`.
- A finished task is squash-merged into `develop` locally and pushed. There are no pull requests.
- A release promotes `develop` to `main` with a fast-forward push (`git push origin develop:main`), then creates the `vX.Y.Z` tag and GitHub release from the CLI.
- Release notes are written by the agent from the commits in the release range; there is no release-drafter and there are no release labels.

## Skill Copies

- `skills/` is the source of truth for every skill and is built into `dist/` for distribution.
- This repository keeps synced copies of its repo-scoped skills under `.agents/skills` (Codex, `spai-` prefixed to match the shipped payload) and `.claude/skills` (Claude Code, unprefixed development copies). When a skill under `skills/` changes, update both copies in the same task.

## Safety Rules

- Do not force push.
- Do not delete branches without explicit user confirmation.
- Do not overwrite user-modified files without explicit user confirmation.
- Do not create unrequested AI skill directories beyond `.agents/skills` and `.claude/skills`.
- Do not push ordinary work directly to `main`; `main` only updates through the release fast-forward push.
- Keep all documentation and skill examples generic: use placeholders such as `your-account`, `your@email.com`, and `/absolute/path/to/<name>`. Never include local machine paths, personal identifiers, or examples taken from local or other projects.
- If a release request includes unfinished code, config, documentation, generated `dist`, or workflow changes, stop release execution and complete those changes first through `develop-task-flow`.
- If `git push origin develop:main` would not fast-forward, stop and report; never force-push to resolve it.
- Preserve unrelated user changes.

## Develop Task Rules

- Use `develop-task-flow` for normal code/config/docs work.
- Create task branches from `origin/develop` using `feature/<slug>`, `fix/<slug>`, or `chore/<slug>`.
- Run relevant tests before merging.
- Finish by `git merge --squash` into `develop` and a single conventional commit, then push `develop`.
- Squash commit subjects use a conventional prefix (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`); bodies carry Korean, user-perspective, release-note-ready bullets with technical terms in backticks.
- These squash commits are the release-note source: `feat:` renders under `🚀 Enhancements`, `fix:` under `🐛 Fixes`, everything else under `🧰 Chores`.

## Release Rules

- Release only when the user explicitly asks for a release.
- Grade the bump by what installed projects pay, not by the kind of change: `patch` when the public interface is unchanged, `minor` for new capability or a break that fails loudly and names its own fix, `major` when a human decision is needed or behavior changes silently. A silent behavior change is always `major`. The full policy is `docs/versioning.md`.
- While the major version is `0`, a `major` grade raises the minor position (`v0.Y.Z` → `v0.(Y+1).0`).
- Compute the next version from the latest `vX.Y.Z` tag using the graded bump type; an explicit `vX.Y.Z` from the user overrides it. If the grade exceeds the requested bump, report the reason and ask before continuing.
- Verify a clean worktree, `develop` synced with `origin/develop`, and a non-existing tag before promoting.
- Promote with `git push origin develop:main` (fast-forward only), tag the released commit, and publish with `gh release create`.
- Write the release notes from `git log <previous>..<version> --no-merges`: categorized `## Changes` sections plus a Korean `### Summary`, and a `### Migration` section when installed projects must take repository-side action.

## Reporting

When doing release work, report:

- Current repo and branch
- Previous and new version
- Promotion, tag, and release status
- Blocked commands and reasons
