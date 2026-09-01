---
name: conformance-audit
description: "Use to check whether a repository's history actually followed the jig procedure: conventional squash subjects, Release-Grade trailers on unreleased work, version tag format and placement, the main/develop fast-forward invariant, and a committed rubric. Read-only, exits non-zero on violations, and runs in CI."
---

# Conformance Audit

Use this repository skill to verify **after the fact** that the procedure was followed. The push guards stop a bad push while it happens; nothing else checks that what did land matches the rules.

Three skills look at a repository and none of them overlap:

| Skill | Subject | Writes |
|---|---|---|
| `jig-doctor` | the jig installation | nothing |
| `repo-hygiene` | debris in the local clone | deletes what the user names |
| `conformance-audit` | the history the procedure produced | nothing |

This one never edits, deletes, or rewrites anything. Its output is a report and an exit code.

## Why a Baseline

A repository that installs jig today has years of history written under other rules. Judging all of it reports the repository as broken on day one and teaches the user to ignore the tool.

Every run therefore starts from a baseline and judges nothing before it:

1. `--since <ref>` when the user names one.
2. The commit that added `.jig/versioning.md` — the point the repository adopted the grading contract.
3. The oldest `vX.Y.Z` tag.
4. Nothing resolves → stop with a usage error. Never fall back to the whole history.

Always report which baseline was used and where it came from. A finding means nothing without it.

## What a Missing Grade Costs

`develop-task-flow` records a `Release-Grade` trailer at merge, and `github-release` reads the highest one in the release range as a floor it never lowers.

When no commit in the range carries a trailer, that lookup returns an empty string. The release does not fail and does not warn; it silently grades from the advisory path floor alone, which says what was touched and never how. A repository can ship many versions that way without one visible symptom.

That is why zero coverage is a violation while partial coverage is only a note: partial adoption is a repository mid-migration, zero is a floor that no longer exists.

## Checks

| ID | What it looks for | Level |
|---|---|---|
| `subject-prefix` | commits with no conventional type | violation |
| `subject-type` | a type outside `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci` | note |
| `grade-coverage` | no `Release-Grade` in the release range (partial → note) | violation |
| `grade-value` | a trailer that is not one lowercase `patch`, `minor`, or `major` | violation |
| `tag-format` | tags outside `^v[0-9]+\.[0-9]+\.[0-9]+$` | violation |
| `tag-on-main` | a version tag `main` cannot reach | violation |
| `main-ancestry` | `main` is not an ancestor of `develop` | violation |
| `main-lineage` | commits on `main` that `develop` cannot reach | violation |
| `rubric-tracked` | the rubric is missing, untracked, or uncommitted | note |

The release range is the latest `vX.Y.Z` tag to `develop`, or the baseline to `develop` when the repository has no tags yet.

## Running It

```bash
sh scripts/audit-history.sh [--since <ref>] [--develop <branch>] [--main <branch>] [--quiet]
```

Paths are relative to this skill directory. The script prefers `origin/<branch>` over the local branch, so a stale local checkout does not change the verdict.

Exit codes are the CI contract: `0` conforming, `1` violations found, `2` usage or environment error. A CI job runs the script and gates on the exit code; `--quiet` trims it to findings and the summary line.

## Safety Rules

- Never rewrite history to satisfy a finding. No `rebase`, no `commit --amend`, no `filter-branch`, no force push.
- A missing trailer on a past commit is not repairable. Record it as observed and grade correctly from the next task onward.
- Do not create, move, or delete tags or GitHub releases. Mismatches are reported for a human to settle.
- Do not delete branches. That is `repo-hygiene`, and only with confirmation.
- Do not write `.jig/`. Only `version-rubric` owns the rubric file.
- Do not modify any tracked file. This skill produces a report, nothing else.
- Report the exact command for anything that could not run rather than approximating its result.
- Preserve unrelated user changes.

## Procedure

1. Confirm the current directory is a git repository and run `git fetch origin --prune --tags` when a remote exists.
2. Resolve the baseline and state it before anything else.
3. Run `scripts/audit-history.sh`, passing `--since` when the user named one.
4. Read each finding against what the repository is actually doing. A note is context, not a defect to fix on the spot.
5. Name the remedy for each violation without performing it:
   - `subject-prefix`, `grade-coverage`, `grade-value` → `develop-task-flow` on the next task; past commits stay as they are
   - `main-ancestry`, `main-lineage` → `hotfix-flow` step 8, which merges `main` back into `develop`
   - `tag-format`, `tag-on-main` → a human decision; report the tag and stop
   - `rubric-tracked` → `version-rubric`, then commit the file
6. Report, and say plainly when the repository conforms. A clean result is the expected outcome, not a skipped check.

## Final Report

Write the report in the language the repository already uses.

```md
## Conformance Audit

- Baseline: <short sha> (<explicit | rubric commit | oldest tag>)
- Range: <baseline or tag>..<develop>
- Violations: none | <id>: <one line each>
- Notes: none | <id>: <one line each>
- Release invariant: ok | **main is not an ancestor of develop, next release blocked**
- Skipped checks and why: <list or none>
- Next: none | <action, named as the skill that owns it>
```
