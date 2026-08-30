# Version Rubric

<!-- jig:skill-source-digest 6a2e0de923555ca9e170cb92c5d1960b88048fd2 -->

[한국어](../../ko/skills/version-rubric.md) · [Skill index](index.md) · [Rubric contract](../version-rubric.md)

## Overview

`version-rubric` exclusively creates, reviews, re-settles, or edits the project-owned version policy resolved from `JIG_VERSION_RUBRIC`, local `jig.versionRubric`, or `.jig/versioning.md`. It never runs a release.

## When to use

Use it when the rubric is missing, when reviewing how the project grades `patch`/`minor`/`major`, when adopting a catalog type, editing one grade, resetting to the default, or explicitly converting legacy Korean section titles.

## Invocation and file contract

- Claude Code: `/jig:version-rubric`
- Codex and Antigravity: `jig-version-rubric`
- Required sections: `## Decision Order`, `## Grade Definitions`
- Optional: `## Hard Rules`, `## Interface Paths`, `## Release Notes`, `## Version Format`, `## Pre-Release Checks`

`## Interface Paths` maps path globs to the lowest grade a change under them can be, so `develop-task-flow` and `github-release` can compute a starting grade from `git diff --name-only` instead of reading a prose interface list by eye. First matching row wins, and the floor it produces is advisory: a release may land below it with a recorded reason.

Legacy Korean titles remain valid but must not be mixed with English titles. The `> Basis:` line records default adoption, catalog type, or project-specific origin. The file must be committed so clones and CI grade the same way.

## Workflow

```mermaid
flowchart TD
    Resolve[Resolve rubric path and source] --> Exists{File exists?}
    Exists -- Yes --> Review[Report basis, grades, titles, commit state]
    Review --> Intent{Keep, re-set, edit, reset, convert?}
    Intent -- Keep --> Report[No change]
    Intent -- Edit --> Edit[Change only requested grade or titles]
    Intent -- Re-set --> Offer[Show default and ask one question]
    Intent -- Reset --> Default[Write default with new Basis]
    Exists -- No --> Offer
    Offer -- Yes --> Default
    Offer -- No --> Catalog[Offer catalog or run rubric-scan]
    Catalog --> Fit{Type fits?}
    Fit -- Yes --> Adopt[Write selected draft]
    Fit -- No --> Custom[Collect project wording for three grades]
    Edit --> Commit[Hand change to develop-task-flow]
    Default --> Commit
    Adopt --> Commit
    Custom --> Commit
    Commit --> Report
```

The default grades on human intervention. Catalog drafts grade SemVer consumer compatibility. They are alternative axes and must be adopted whole, not mixed question by question.

## Reads and writes

It reads the resolved rubric, Git commit state, catalog `INDEX.md`, one selected catalog draft, and repository context. It writes only the resolved rubric path and its parent `.jig/` directory, then delegates committing to `develop-task-flow` when available. The catalog is shipped payload and is never edited to record a project choice.

## Decision points and safety

- Show and confirm before replacing an existing rubric.
- If a create/re-set question is skipped, adopt the default and record that in `> Basis:`.
- Preserve the user's language and vocabulary; rephrasing changes future grading.
- Never silently translate/retitle, create `.bak`, modify catalog files, grade a release, touch GitHub settings, or force a commit.
- Warn before overwriting an untracked or uncommitted rubric.

## Outputs

The report includes path/source, basis, title spelling, three grade questions, action taken, draft source, commit status, and next action.

## Related skills

- [`rubric-scan`](rubric-scan.md) recommends a catalog type without writing.
- [`github-release`](github-release.md) reads the settled rubric.
- [`jig-setup`](jig-setup.md) delegates missing rubric creation here.
- [`jig-doctor`](jig-doctor.md) diagnoses missing, broken, or uncommitted rubrics.

## Source

- [`skills/version-rubric/SKILL.md`](../../../skills/version-rubric/SKILL.md)
- [Rubric catalog](../../../skills/version-rubric/rubrics/INDEX.md)
- [Human-readable contract](../version-rubric.md)
