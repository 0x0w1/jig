---
name: spai-github-release
description: Use when releasing this repository from the CLI by promoting develop to main with a fast-forward push, grading the release as patch/minor/major by what installed projects actually pay, computing the next version from the latest tag, and publishing a GitHub release with agent-written notes. No release PR, no release-drafter.
---

# GitHub Release

Use this repository skill for release execution.

## Release Model

- A release promotes the current `origin/develop` to `main` with a fast-forward push: `git push origin develop:main`. There is no release PR and no `release/*` branch.
- `develop` must already contain every intended release change, squash-merged through `develop-task-flow`.
- The next version is computed from the latest `vX.Y.Z` tag using the requested bump type:
  - `patch`: `vX.Y.Z` → `vX.Y.(Z+1)` (default when no type is given)
  - `minor`: `vX.Y.Z` → `vX.(Y+1).0`
  - `major`: `vX.Y.Z` → `v(X+1).0.0`, except before 1.0 (see Version Policy)
  - An explicit `vX.Y.Z` from the user overrides the computed version.
- The release tag and GitHub release are created from the CLI with `git tag` and `gh release create`.
- Release notes are written by the agent from the commits in `<previous tag>..<new tag>`, categorized by conventional commit prefix.

## Version Policy

The bump is decided by what an installed project actually pays, not by the kind of change. The primary consumer of a release note is the `spai-update` skill, so a break an agent repairs unattended is not the same cost as one a human must decide.

Ask these in order and stop at the first match:

1. Do installed projects need nothing, or does re-running the update converge them? → `patch`
2. Does something break, but either (a) `spai-update` repairs it unattended, or (b) the tool **fails loudly at the point of use and names the replacement**? → `minor`
3. Does it need a **human decision**, or does behavior change **silently** without failing? → `major`

| bump | Definition |
|---|---|
| `patch` | The public interface is unchanged. Internal implementation, docs, skill body wording, `dist` regeneration. |
| `minor` | New capability, or a **guided break**: the failure is loud and carries its own fix. |
| `major` | A **human decision** is required, or behavior changes **silently**. Branch model or protection policy changes, deletion of user files or labels, a command that returns a different result without erroring. |

The loosening is that a repairable break is `minor`. It is paid for by one hard rule:

> A silent behavior change is always `major`, regardless of how small it looks.

### Migration Blocks

The `### Migration` section is not prose. It is the input `spai-update` executes, so it is written as marker-delimited blocks:

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

When in doubt, an item is `manual`. Either block may be omitted; omit the whole section when neither applies.

**A marker counts only when it is the entire line**, matching `^<!-- spai:(start|end) migration-(auto|manual) -->$`. Release notes routinely name these markers in prose, so a mention inside backticks or mid-sentence is text, not a marker. Keep marker lines flush left with nothing else on them, and always close a block with its matching end marker.

### The Notes Decide the Version

The presence of these blocks forces the bump, so the grade is derived rather than chosen:

| In the notes | Required bump |
|---|---|
| No Migration section | `patch` or `minor`, per the ordered questions |
| `migration-auto` only | at least `minor` |
| any `migration-manual` | **`major`** |

If the composed notes and the intended bump disagree, one of them is wrong. Stop and resolve it before publishing rather than adjusting the notes to fit the version.

### Public Interface

A break here counts as a break. Anything else is internal and stays `patch`.

1. The installer one-liner shape: `--target`, `--scope`, `--github-account`
2. Skill invocation names: `/spai:<skill>`, `spai-<skill>`
3. Plugin and marketplace names: `spai@spai`, `0x0w1/spai`
4. Managed block markers: `<!-- spai:start ... -->`, `<!-- spai:end ... -->`
5. The repository model: branch names, merge flow, protection policy

Internal: `dist/` layout, `scripts/*`, skill body content, version stamp fields other than the version itself, log wording, `README` and `docs` structure.

### Before 1.0

While the major version is `0`, a `major` verdict raises the minor position instead: `v0.Y.Z` → `v0.(Y+1).0`. Judge the grade exactly as after 1.0 and state the verdict in the report, so the rule is exercised before it becomes binding.

The full policy with worked examples lives in `docs/versioning.md`; keep the two in agreement.

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
3. Grade the release against the Version Policy before computing anything: read the commit subjects and bodies in the range, decide `patch`, `minor`, or `major`, and note which Public Interface items the range touches.
   - If the graded bump is higher than the one the user requested, say so with the specific reason and ask before continuing. The user's choice wins if they repeat it; record the graded verdict in the report either way.
   - If the graded bump is lower, use the requested one; a user may always release higher than required.
4. Verify `origin/develop` already contains every intended release change. If not, stop and run the Develop-First Gate.
5. Compose the release notes from `git log <previous>..HEAD --no-merges`. Do this **before** promoting or tagging, because the notes can still change the version:
   - `## Changes` with these sections in order, each only when it has items, separated by horizontal rules:
     - `### 🚀 Enhancements` for `feat:` commits
     - `### 🐛 Fixes` for `fix:` commits
     - `### 🧰 Chores` for all other commits
   - One `- <commit subject without type prefix>` line per commit.
   - `### Summary`: Korean user-perspective bullet items the agent writes from the commit subjects and bodies, release-note ready, with technical terms in backticks.
   - `### Migration`: only when installed projects must take repository-side action that re-running the update does not cover. Write it as `migration-auto` and `migration-manual` marker blocks per Migration Blocks; `spai-update` executes the first and gates the second.
6. Re-check the bump against the composed notes, counting **line-anchored markers only** (`grep -cE '^<!-- spai:start migration-manual -->$'`; a bare substring search also matches prose that names the marker):
   - a `migration-manual` block requires `major`
   - a `migration-auto` block requires at least `minor`
   - an opened block with no matching end marker is a defect; fix the notes before publishing
   - if this raises the grade from step 3, go back to step 3 and resolve it with the user. Never weaken the notes to fit a version.
7. Compute the new version from the settled bump type, or validate the explicit version. The version must match `^v[0-9]+\.[0-9]+\.[0-9]+$` and must not exist as a tag or release. Before 1.0, a `major` grade raises the minor position.
8. Run repository validation when available (for this repository: `sh scripts/validate-dist.sh`).
9. Promote: `git push origin develop:main`. This must fast-forward; if rejected, stop and report.
10. Tag the released commit: `git tag <version> <develop sha>` then `git push origin <version>`.
11. Publish: `gh release create <version> --title "<version> 🌈" --notes-file <draft file>`.
12. Verify the release and tag exist (`gh release view <version>`).

## Final Report

Keep reports short and include:

- Current repo and branch
- Previous and new version
- Graded bump versus the requested bump, with the Public Interface items the range touched
- `develop` to `main` promotion result
- Tag and release status
- Release note summary
- Commands that could not run and why
- User next actions, if any
