---
name: spai-github-release
description: Use when releasing this repository from the CLI by promoting develop to main with a fast-forward push, grading the release as patch/minor/major by what installed projects actually pay, computing the next version from the latest tag, and publishing a GitHub release with agent-written notes. No release PR, no release-drafter.
---

# GitHub Release

Use this repository skill for release execution.

## Release Model

- A release promotes the current `origin/develop` to `main` with a fast-forward push: `git push origin develop:main`. There is no release PR and no `release/*` branch.
- `develop` must already contain every intended release change, squash-merged through `develop-task-flow`.
- The bump is graded against this project's version rubric, not against a rule inside this skill. See Version Rubric.
- The next version is computed from the latest `vX.Y.Z` tag using the graded bump type. See Version Format.
- The release tag and GitHub release are created from the CLI with `git tag` and `gh release create`.
- Release notes are written by the agent from the commits in `<previous tag>..<new tag>`, categorized by conventional commit prefix.

## GitHub Profile

Before any `gh` command, resolve the host from `SPAI_GITHUB_HOST`, local `spai.githubHost`, then `github.com`, and resolve the profile from `SPAI_GITHUB_PROFILE`, then local `spai.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Version Rubric

The grading rubric is not in this skill. It is a project-owned file, so every project grades by its own axis. The `version-rubric` skill owns that file.

Resolve the rubric path in this order:

1. `SPAI_VERSION_RUBRIC` environment variable (session-only override).
2. `git config --local --get spai.versionRubric` (repository override).
3. `.spai/versioning.md` (the convention).

Apply it like this:

- Grade with the rubric's `## Decision Order`: ask its questions in order and **stop at the first match**. That ordering is fixed; a rubric cannot change it.
- Check the graded bump against the rubric's `## Grade Definitions` before computing the version, and quote the deciding question in the report.
- Apply `## Hard Rules` after the ordered questions. A rubric without that section has no escalation rule.
- A missing optional section (`## Hard Rules`, `## Release Notes`, `## Version Format`, `## Pre-Release Checks`) means that rule does not apply.
- Rubrics written before the contract switched to English carry Korean titles, and they stay valid. Accept either spelling for every section: `## 판정 순서`, `## 등급 정의`, `## 강경 규칙`, `## 릴리즈 노트`, `## 버전 형식`, `## 릴리즈 전 검증`, and `> 기준:` for `> Basis:`. Read the file as it is; never retitle it during a release.
- Read sections beyond the contract as grading context; a project may list what counts as its public interface there.
- Report the rubric path, its source, and whether it records the adopted default or a project-specific rubric.
- Never edit the rubric file from this skill.

When the rubric is missing or unusable:

- **Missing file**: run the `version-rubric` skill to settle it, then continue the release. Do not stop the release for this.
- **`version-rubric` not installed**: grade with the fallback below, say so in the report, and continue.
- **Contract broken** (neither spelling of the decision-order or grade-definition section is present, or fewer than three ordered questions): stop and point at `version-rubric`. Grading with a broken rubric silently is worse than stopping.

The fallback rubric, used only in the two cases above. It matches the default `version-rubric` writes, so a project grades the same whether or not that skill is installed:

1. Is this a fix inside what the project already does? → `patch`
2. Can people do something new, or did a generation turn over, while everything they already do keeps working? → `minor`
3. Did the value on offer widen, shrink, or change, or must a human step in to keep using it? → `major`

With these escalation rules, applied after the ordered questions:

> A change that raises no error but behaves differently is `major`. Its size does not matter.

> A skill or prompt instruction that changes when the agent speaks is at least `minor`.

## Version Format

Defaults, each overridable by the rubric's `## Version Format` section:

- The version must match `^v[0-9]+\.[0-9]+\.[0-9]+$`.
- `patch`: `vX.Y.Z` → `vX.Y.(Z+1)`; `minor`: → `vX.(Y+1).0`; `major`: → `v(X+1).0.0`.
- While the major version is `0`, a `major` grade raises the minor position instead: `v0.Y.Z` → `v0.(Y+1).0`. Grade exactly as after 1.0 and state the verdict in the report, so the rule is exercised before it becomes binding.
- An explicit `vX.Y.Z` from the user overrides the computed version.

## Release Notes

- `## Changes`, then one section per commit type present in the range, each only when it has items, separated by horizontal rules.
- Section titles derive from the commit prefix: `feat` → `### 🚀 Enhancements`, `fix` → `### 🐛 Fixes`, `chore` → `### 🧰 Chores`. Any other prefix becomes its own section named after it (`docs:` → `### 📚 Documentation`). Never fold an unlisted prefix into chores.
- The rubric's `## Release Notes` section overrides section order and titles.
- One `- <commit subject without type prefix>` line per commit.
- `### Summary`: user-perspective bullet items written from the commit subjects and bodies, release-note ready, with technical terms in backticks. Write them in the language the repository already uses for its release notes and commit bodies, defaulting to English.
- `### Migration`: only when downstream projects must take action that re-running an update does not cover.

## Migration Blocks

The `### Migration` section is not prose. It is the input an updating agent executes, so it is written as marker-delimited blocks:

```md
### Migration

<!-- spai:start migration-auto -->
- `rm -f .github/workflows/drafter.yaml`
- Move `.agents/skills/github-sync/` to `.agents/skills/spai-github-sync/` when it exists
<!-- spai:end migration-auto -->

<!-- spai:start migration-manual -->
- Decide whether `develop` keeps its required status checks; SPAI no longer sets them.
<!-- spai:end migration-manual -->
```

- `migration-auto`: mechanical steps an agent finishes unattended. Every item must be **idempotent** and be either a single command or an unambiguous file operation. A target that is already absent counts as done.
- `migration-manual`: steps needing a human judgement, a choice, or an irreversible action. `spai-update` presents these and does not run them without approval.
- When in doubt, an item is `manual`. Either block may be omitted; omit the whole section when neither applies.
- **A marker counts only when it is the entire line**, matching `^<!-- spai:(start|end) migration-(auto|manual) -->$`. Release notes routinely name these markers in prose, so a mention inside backticks or mid-sentence is text, not a marker. Keep marker lines flush left with nothing else on them, and always close a block with its matching end marker.
- A rubric may key an escalation rule off these blocks; SPAI's own rubric grades any `migration-manual` block as `major`. When applying such a rule, count line-anchored markers only.

## Safety Rules

- Do not force push.
- Do not bypass git hooks: never pass `--no-verify` to `git push`.
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
3. Resolve and read the version rubric, then grade the release against it before computing anything: read the commit subjects and bodies in the range and decide `patch`, `minor`, or `major`. Handle a missing, uninstalled, or broken rubric per Version Rubric.
   - If the graded bump is higher than the one the user requested, say so with the specific reason and ask before continuing. The user's choice wins if they repeat it; record the graded verdict in the report either way.
   - If the graded bump is lower, use the requested one; a user may always release higher than required.
4. Verify `origin/develop` already contains every intended release change. If not, stop and run the Develop-First Gate.
5. Compose the release notes from `git log <previous>..HEAD --no-merges` per Release Notes. Do this **before** promoting or tagging, because the notes can still change the version.
6. Re-check the bump against the composed notes when the rubric has a `## Hard Rules` section that keys off them, counting **line-anchored markers only** (`grep -cE '^<!-- spai:start migration-manual -->$'`; a bare substring search also matches prose that names the marker):
   - an opened block with no matching end marker is a defect; fix the notes before publishing
   - if the rule raises the grade from step 3, go back to step 3 and resolve it with the user. Never weaken the notes to fit a version.
7. Compute the new version from the settled bump type per Version Format, or validate the explicit version. It must not exist as a tag or release.
8. Run the repository's pre-release validation: the commands in the rubric's `## Pre-Release Checks` section when present, otherwise the validation or test command the repository already uses. Skip and report when there is none.
9. Promote: `git push origin develop:main`. This must fast-forward; if rejected, stop and report.
10. Tag the released commit: `git tag <version> <develop sha>` then `git push origin <version>`.
11. Publish: `gh release create <version> --title "<version> 🌈" --notes-file <draft file>`.
12. Verify the release and tag exist (`gh release view <version>`).

## Final Report

Keep reports short and include:

- Current repo and branch
- Previous and new version
- Rubric path, source, and kind (adopted default or project-specific)
- Graded bump versus the requested bump, with the rubric question that decided it
- `develop` to `main` promotion result
- Tag and release status
- Release note summary
- Commands that could not run and why
- User next actions, if any
