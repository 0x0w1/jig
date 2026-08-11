Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `spai-doctor`: diagnose the installed SPAI state (version, drift, protection, legacy); read-only.


## github-sync


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

## github-release


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

## develop-task-flow


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

## spai-update


# SPAI Update

Use this repository skill to update the installed SPAI procedures to the latest release.

## Update Model

- The installed version and skill selection are stamped inside the SPAI managed block as `<!-- spai:version vX.Y.Z flow=solo-cli skills=<a,b,c> -->` in `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`. A stamp without `skills=` means the full default skill set. `solo-cli` is the only flow; a stamp naming another flow comes from a removed profile and updates to the current defaults.
- The latest version is the latest GitHub release tag of `0x0w1/spai`.
- An update re-runs `install.sh` pinned to the latest tag. The installer is idempotent: unchanged files pass, changed files are backed up as `*.bak`, and managed blocks are replaced in place.
- Repository-side convergence (branch protection, legacy release-drafter file and label cleanup) is handled by the `github-sync` skill after the file update, and is idempotent across skipped versions.
- A `major` version jump means the release flow or repository policy changed; read the `### Migration` sections of the release notes before updating.

## Safety Rules

- Do not force push.
- Do not run the installer with `--force` unless the user explicitly asks for a full template replacement.
- Do not delete branches, labels, or files without explicit confirmation; leave `*.bak` backups in place.
- Do not create releases or tags.
- Stop and report if the installer fails or the version stamp does not update.
- Preserve unrelated user changes.

## Procedure

1. Read the installed version stamp:
   - `grep -h "spai:version" CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null | head -n 1`
   - A missing stamp means an install without a version stamp; continue and treat the installed version as unknown.
2. Determine the latest release:
   - `gh api repos/0x0w1/spai/releases/latest --jq .tag_name`
   - Fallback without `gh`: `curl -fsSL https://api.github.com/repos/0x0w1/spai/releases/latest` and read `tag_name`.
3. If the installed stamp equals the latest tag, report up to date and stop.
4. Collect the release notes between the installed version and the latest:
   - `gh release list --repo 0x0w1/spai --limit 20`
   - `gh release view <tag> --repo 0x0w1/spai` for each release newer than the installed version.
   - Extract any `### Migration` sections.
5. Report the version delta with a short Korean summary of the changes and highlight migration steps. Ask for approval before applying, unless the user already asked for the update to be executed end to end.
6. Determine the GitHub account for the installer: the active `gh` account (`gh api user --jq .login`) or ask the user.
7. Detect the installed targets and re-run the installer pinned to the latest tag for each:
   - `./CLAUDE.md` with SPAI markers or `.claude/skills/` → `claude-code`
   - `./AGENTS.md` with SPAI markers → `codex`
   - `./GEMINI.md` with SPAI markers → `antigravity`
   - Command per target, preserving the stamped selection:
     `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh | sh -s -- --target <target> --scope project --github-account <account> --version <latest> --skills <stamped skills>`
   - When the stamp has no `skills=`, omit `--skills` so the installer applies the defaults. Never pass `--flow` with a value other than `solo-cli`; the installer rejects it.
8. Verify the stamp now shows the latest version.
9. Run the `github-sync` skill to converge branch protection and report legacy release-drafter files or labels; delete them only with explicit confirmation.
10. Run the `spai-doctor` skill to confirm the updated installation is healthy; include its findings in the report.
11. Report.

## Final Report

Keep reports short and include:

- Installed version before and after
- Releases applied and their key changes
- Migration steps executed or still pending
- Files updated or backed up
- Commands that could not run and why
- User next actions, if any

## spai-doctor


# SPAI Doctor

Use this repository skill to diagnose the installed SPAI state. This skill never modifies files or settings.

## Checks

1. **Version**: read the installed stamp (`grep -h "spai:version" CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null | head -n 1`) and compare with the latest release tag (`gh api repos/0x0w1/spai/releases/latest --jq .tag_name`). Also read `skills=` from the stamp; a stamp without it means the full default skill set, and a missing stamp means an install without a version stamp. A stamp with `flow=` other than `solo-cli` comes from a removed flow profile: report it and recommend reinstalling with the current defaults.
2. **Drift**: for each installed skill file, compare with the payload of the stamped version:
   - claude-code: `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/<stamp>/dist/claude-code/.claude/skills/<skill>/SKILL.md | cmp -s - .claude/skills/<skill>/SKILL.md`
   - codex: same with `dist/codex/.agents/skills/<skill>/SKILL.md`
   - antigravity: same with `dist/antigravity/.agents/skills/<skill>/SKILL.md`
   - A `cmp` mismatch means the file was locally modified or partially updated. If the stamp is `main` or `custom`, drift cannot be judged against a fixed payload; report that instead.
3. **Branch protection**: `gh api repos/<owner>/<repo>/branches/<branch>/protection` for `main` and `develop`. Expected on both branches: no required pull request reviews, no required status checks, `allow_force_pushes.enabled == false`, `allow_deletions.enabled == false`. A 404 means no protection is configured.
4. **Branch state**: after `git fetch origin --prune`, run `git rev-list --left-right --count origin/main...origin/develop`. If `main` is ahead of `develop` (left count > 0), the next release cannot fast-forward; report it.
5. **Legacy leftovers** (report existence only):
   - `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`
   - labels `patch`, `minor`, `major`, `enhancement`, `fix`, `chore` (`gh label list`)
   - knowledges leftovers: `.claude/skills/knowledges-quick-ingest/`, `.claude/rules/knowledges-raw-contract.md`, `.claude/guardrails/knowledges-ingest.md`, the same paths under `.agents/`, `.cursor/rules/knowledges-*.mdc`, and a `KNOWLEDGES_ROOT` entry in `.env`
   - leftover backups: `find . -name "*.bak" -not -path "./.git/*"`

## Safety Rules

- Read-only: do not modify files, settings, branches, or labels.
- Do not run the installer; recommend `spai-update` instead.
- Report the exact command for each recommended fix, but do not execute it.
- Preserve unrelated user changes.

## Procedure

1. Confirm context: `git rev-parse --is-inside-work-tree`, `gh repo view`, `gh auth status`. If `gh` is unavailable, run only the local checks (stamp read, local legacy files, backups) and list the skipped checks in the report.
2. Run checks 1–5 in order and collect the results.
3. Compose the report. For every finding, name the fix owner:
   - version behind or drifted files → `spai-update` (re-installs with `*.bak` backups)
   - protection mismatch or legacy leftovers → `github-sync` (deletions only with explicit confirmation)
   - branch state divergence → stop releases and reconcile manually; never force-push.

## Final Report

```md
## SPAI 진단 보고서

### 버전
- 설치: <stamp> / 최신: <latest> → 최신 여부

### 드리프트
- 없음 | 불일치 파일 목록

### 브랜치 보호
- main: OK | 항목별 불일치
- develop: OK | 항목별 불일치

### 브랜치 상태
- OK | main이 N커밋 앞섬 (fast-forward 릴리즈 불가)

### 레거시
- 없음 | 발견 항목 목록

### 권장 조치
- <fix owner>: <명령 또는 스킬>
```

<!-- spai:end github-release-setup -->
