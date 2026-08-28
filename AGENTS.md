# Codex Rules

Use these repo-scoped Codex skills:

- Repository setup/sync: `jig-github-sync` from `.agents/skills/jig-github-sync/SKILL.md`.
- Release: `jig-github-release` from `.agents/skills/jig-github-release/SKILL.md`.
- Ordinary implementation tasks targeting `develop`: `jig-develop-task-flow` from `.agents/skills/jig-develop-task-flow/SKILL.md`.
- README writing/updating: `jig-readme` from `.agents/skills/jig-readme/SKILL.md`.
- jig project installation and GitHub profile setup: `jig-setup` from `.agents/skills/jig-setup/SKILL.md`.
- jig installation updates: `jig-update` from `.agents/skills/jig-update/SKILL.md`.
- jig installation diagnostics: `jig-doctor` from `.agents/skills/jig-doctor/SKILL.md`.
- Version grading rubric: `jig-version-rubric` from `.agents/skills/jig-version-rubric/SKILL.md`.
- Project type scan and rubric recommendation: `jig-rubric-scan` from `.agents/skills/jig-rubric-scan/SKILL.md`.

## Repository Model

- `main` and `develop` are protected against force pushes and deletion; direct pushes are allowed.
- Work branches start from `origin/develop`: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`.
- A finished task is squash-merged into `develop` locally and pushed. There are no pull requests.
- A release promotes `develop` to `main` with a fast-forward push (`git push origin develop:main`), then creates the `vX.Y.Z` tag and GitHub release from the CLI.
- Release notes are written by the agent from the commits in the release range; there is no release-drafter and there are no release labels.

## Skill Copies

- `skills/` is the source of truth for every skill and is built into `dist/` for distribution.
- Skill bodies and the rubric catalog are written in English; the rubric file contract uses English section titles with the Korean spellings still accepted as legacy. What a skill *produces* (reports, commit bodies, release notes, README) follows the target repository's own language, defaulting to English.
- This repository keeps synced copies of its repo-scoped skills under `.agents/skills` (Codex, `jig-` prefixed to match the shipped payload) and `.claude/skills` (Claude Code, unprefixed development copies). When a skill under `skills/` changes, update both copies in the same task.

## Build

- Rebuild the distribution after any change under `skills/`, `hooks/`, or `manifest.tsv`: `sh scripts/build-dist.sh`.
- Validate before merging or releasing: `sh scripts/validate-dist.sh`. It checks the payload file list, managed block markers, the rubric catalog contract, and the README layout rules.
- `dist/` is generated, never hand-edited. The Claude Code plugin payload is `dist/claude-code-plugin/jig` and the marketplace definition is `.claude-plugin/marketplace.json`.

## Safety Rules

- Do not force push.
- Do not delete branches without explicit user confirmation.
- Do not overwrite user-modified files without explicit user confirmation.
- Keep repository skill copies under `.agents/skills` and `.claude/skills`, synced from `skills/`.
- Do not create `.codex` or unrequested AI skill directories beyond those two inside this repository.
- `.jig/` is project-owned: only `jig-version-rubric` writes `.jig/versioning.md`, and the installer and `jig-update` never touch it.
- The project-type rubric catalog lives at `skills/version-rubric/rubrics` and ships as payload; `jig-rubric-scan` reads it and never writes. `rubrics/INDEX.md` is the only list of types, so a new rubric file must be added to that table in the same task.
- Do not push ordinary work directly to `main`; `main` only updates through the release fast-forward push.
- Keep all documentation and skill examples generic: use placeholders such as `your-account`, `your@email.com`, and `/absolute/path/to/<name>`. Never include local machine paths, personal identifiers, or examples taken from local or other projects.
- If a release request includes unfinished code, config, documentation, generated `dist`, or workflow changes, stop release execution and complete those changes first through `develop-task-flow`.
- If `git push origin develop:main` would not fast-forward, stop and report; never force-push to resolve it.
- In a table whose first column holds identifiers people copy (skill names, commands, options, paths), keep the description cells about as short as the identifiers. GitHub sizes columns by content, so long descriptions squeeze the identifier column until a name wraps mid-word. Trim the description or switch to a list; wrapping inside a description is fine.
- `README.md` is the English canonical README and `README.ko.md` is its Korean mirror. A change to one is made in the other in the same task, and Korean prose never lands in `README.md`.
- Preserve unrelated user changes.

## Develop Task Rules

- Use `jig-develop-task-flow` for normal code/config/docs work.
- Create task branches from `origin/develop` using `feature/<slug>`, `fix/<slug>`, or `chore/<slug>`.
- Run relevant tests before merging.
- Finish by `git merge --squash` into `develop` and a single conventional commit, then push `develop`.
- Squash commit subjects use a conventional prefix (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`); bodies carry Korean, user-perspective, release-note-ready bullets with technical terms in backticks.
- These squash commits are the release-note source. Sections derive from the prefix: `feat:` → `🚀 Enhancements`, `fix:` → `🐛 Fixes`, `chore:` → `🧰 Chores`, any other prefix → its own section (`docs:` → `📚 Documentation`).

## Release Rules

- Release only when the user explicitly asks for a release.
- Grade the bump against this repository's version rubric at `.jig/versioning.md`, which grades by what installed projects pay: `patch` when the public interface is unchanged, `minor` for new capability or a break that fails loudly and names its own fix, `major` when a human decision is needed or behavior changes silently. A silent behavior change is always `major`, and any `migration-manual` block forces `major`. `docs/en/versioning.md` is the English commentary, `docs/ko/versioning.md` is its Korean mirror, and the matching `version-rubric.md` files explain the contract for installed projects.
- While the major version is `0`, a `major` grade raises the minor position (`v0.Y.Z` → `v0.(Y+1).0`).
- Compute the next version from the latest `vX.Y.Z` tag using the graded bump type; an explicit `vX.Y.Z` from the user overrides it. If the grade exceeds the requested bump, report the reason and ask before continuing.
- Verify a clean worktree, `develop` synced with `origin/develop`, and a non-existing tag before promoting.
- Promote with `git push origin develop:main` (fast-forward only), tag the released commit, and publish with `gh release create`.
- Write the release notes from `git log <previous>..<version> --no-merges`: categorized `## Changes` sections plus a Korean `### Summary`.

## Reporting

When doing release work, report:

- Current repo and branch
- Previous and new version
- Promotion, tag, and release status
- Blocked commands and reasons
