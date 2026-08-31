---
name: jig-version-rubric
description: "Use when creating, reviewing, or re-setting this repository's version grading rubric at .jig/versioning.md: adopt the jig default human-intervention rubric, write a project-specific one, edit one grade, or reset to the default. Owns the rubric file; never runs a release."
---

# Version Rubric

Use this repository skill to decide and maintain how this project grades `patch`, `minor`, and `major`. The decision lives in a project-owned Markdown file that `github-release` reads at release time.

Run this skill whenever the rubric needs to be created, reviewed, or changed. It is safe to run repeatedly.

## Rubric File

Resolve the rubric path in this order:

1. `JIG_VERSION_RUBRIC` environment variable (session-only override).
2. `git config --local --get jig.versionRubric` (repository override; not propagated by clone).
3. `.jig/versioning.md` (the convention).

- `.jig/` is owned by the project, not by jig. The installer and `jig-update` never write or delete it, and `jig-doctor` never treats it as drift.
- The file must be committed. `git config --local` lives in `.git/config` and is not propagated by clone or CI checkout, so a config-only setup grades differently for different people.
- Never store state such as "the default was adopted" in a config key. That belongs in the file's `> Basis:` line, which is the single record of the decision.

### File Contract

Two required sections, six optional. The section titles are the contract.

```md
# Version Policy

> Basis: jig default (human-intervention axis) | project-specific, <date>

## Decision Order        (required)
1. <question> → `patch`
2. <question> → `minor`
3. <question> → `major`

## Grade Definitions     (required)
| bump | definition |

## Hard Rules            (optional) conditions that always escalate
## Interface Paths       (optional) changed paths that set a starting grade
## Hotfix Triggers       (optional) what justifies bypassing the develop queue
## Release Notes         (optional) note section order and titles
## Version Format        (optional) tag pattern, pre-1.0 handling, summary language
## Pre-Release Checks    (optional) commands to run before releasing
```

- `## Decision Order` is asked in order and **stops at the first match**. A rubric cannot change that meaning.
- An optional section a rubric omits simply does not apply to that project. No `## Hard Rules` means no escalation rule, even though the default below ships two.
- The `> Basis:` line records whether the default was adopted or the rubric was written for the project.
- Sections beyond these are read as context, not ignored. A project may add its own, such as a list of what counts as its public interface.

### Interface Paths

`## Public Interface`, where a rubric has one, is prose: a reader decides whether a change touched it. `## Interface Paths` is the machine-readable companion, so the grading skills can compute a starting grade from the diff instead of eyeballing it.

```md
## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `src/api/**` | the HTTP surface consumers call | `minor` |
| `docs/**` | internal | `patch` |
```

- A changed path takes the floor of the **first row it matches**, so order specific globs above general ones. The path floor for a range is the highest floor any changed path took.
- A path matching no row contributes nothing. A table that lists only the public paths is complete; there is no need to enumerate the internal ones.
- **The floor is advisory.** Paths say what changed, never how, so a typo fix and a contract break under the same glob match the same row. A grade below the path floor is allowed and must record its reason; a grade above it needs no justification.
- This is the opposite of a recorded task grade, which is a judgement made with the diff in hand and is never lowered. Keep the two apart in the report.
- Write the globs against repository-root-relative paths, matching what `git diff --name-only` prints.

### Hotfix Triggers

`hotfix-flow` puts a commit on `main` that `develop` does not have, which is the one operation the branch model otherwise forbids. Whether a defect deserves that is a judgement, and a judgement made while something is on fire is the least reliable kind.

This section moves the judgement earlier. The project writes, while calm, the question that decides the bypass and the conditions it has already recognised; `hotfix-flow` then requires the run to answer against them.

```md
## Hotfix Triggers

> Does harm keep occurring and accumulating for as long as the released state stands?

- The released artifact does not install or start
- Data is lost or corrupted
- A credential or secret is exposed
```

The leading `>` line is the **anchoring question**, and the list is what answering it has produced so far. A closed list is wrong eventually, and a gate people route around is worse than no gate, so the question is what the list is measured against.

- Every item is an **observable state**, not a feeling. "Urgent" is not a trigger; "the released CLI exits non-zero on startup" is.
- The question is about the world, not about the person asking. "We have a demo tomorrow" and "the release is overdue" describe a schedule; neither says anything keeps happening because the released state stands. That is what makes the question answerable by someone other than the requester.
- When nothing on the list matches, `hotfix-flow` puts the question instead. A `no` ends the run and the fix goes to `develop-task-flow`. A `yes` does not start the hotfix either: the new condition is added to this section and committed on its own first, so the list grows by decision rather than by exception.
- Omit the section and `hotfix-flow` falls back to the question and list it ships, exactly as `github-release` falls back to the default rubric. A project that never wrote this section still grades and still gates.

**This section is not written per project type.** Domain wording differs — a blank screen, a 5xx, a corrupted state file — but each is the same answer to the same question, so a catalog draft restates rather than decides. Keep the question general and let the project add the two or three conditions it has actually met.

### Legacy Section Titles

Rubrics written before this contract switched to English carry Korean titles. They stay valid, and every jig skill that reads a rubric accepts either spelling:

| English (canonical) | Korean (legacy) |
|---|---|
| `## Decision Order` | `## 판정 순서` |
| `## Grade Definitions` | `## 등급 정의` |
| `## Hard Rules` | `## 강경 규칙` |
| `## Interface Paths` | `## 인터페이스 경로` |
| `## Hotfix Triggers` | `## 핫픽스 트리거` |
| `## Release Notes` | `## 릴리즈 노트` |
| `## Version Format` | `## 버전 형식` |
| `## Pre-Release Checks` | `## 릴리즈 전 검증` |
| `> Basis:` | `> 기준:` |

- A rubric may use one spelling or the other. Do not mix them inside one file: a file with `## Decision Order` and `## 등급 정의` reads as one required section missing.
- Never rewrite an existing rubric's titles on your own. The file is user-owned content, and a silent retitle is a change to how the project grades releases. Offer the conversion, and convert only when the user says so.
- Write new rubrics with the English titles.

## Default Rubric

Offer this as-is. It grades by whether a human has to step in. Scale alone does not survive an AI-paced project: generations turn over fast enough that grading by size inflates `major` until the number carries no information.

```md
# Version Policy

> Basis: jig default (human-intervention axis), adopted <date>

## Decision Order
1. Is this a fix inside what the project already does? → `patch`
2. Can people do something new, or did a generation turn over, while everything they already do keeps working? → `minor`
3. Did the value on offer widen, shrink, or change, or must a human step in to keep using it? → `major`

## Grade Definitions
| bump | definition |
|---|---|
| `patch` | A fix inside the existing feature set: bug fixes, wording and documentation changes, internal cleanup |
| `minor` | A capability added, removed, or changed, or a generation replaced. Something new is possible and the old way still works |
| `major` | The value on offer widened, shrank, or changed, or a human must edit config, files, or call sites to keep using it |

## Hard Rules
> A change that raises no error but behaves differently is `major`. Its size does not matter.

> A skill or prompt instruction that changes when the agent speaks is at least `minor`.

## Version Format
- While the major version is `0`, a `major` grade raises the minor position: `v0.Y.Z` → `v0.(Y+1).0`. Before 1.0, both the value on offer and the call sites may change at any time. Grade exactly as after 1.0 and record the `major` grade in the release report.
- After `v1.0.0`, a `major` grade raises the major position. The grace above ends there.
```

The default ships `## Hard Rules` and `## Version Format` alongside the two required sections:

- The escalation rules exist because the break that matters in an AI project is a quiet one. No test suite confirms that a reworded instruction still fires on the same input, so the version number is the channel left for "a human should look at this."
- While the major version is `0`, `minor` and `major` land on the same position, so the escalation rules cost nothing yet and the `> Basis:` line says so. They begin to bind at `v1.0.0`, which is why they are settled before then.
- A project that wants neither section removes them; both are optional by contract.
- The default ships no `## Interface Paths` table, because it grades by whether a human must step in and that axis names no paths. After writing it, offer to add one built from the project's own public paths; a project that declines keeps grading exactly as before.

A project whose releases ship documents rather than features usually grades by artifact instead: `patch` for document add/edit/delete, `minor` for changes to the tooling that manages the documents, `major` for a restructure. That rubric and a dozen others are already written; take one from the catalog below instead of drafting it.

## Type Catalog

`rubrics/` ships next to this skill and holds one ready draft per project type. Every file in it is a complete rubric: copy it to the resolved rubric path, fill the `> Basis:` date, and adjust the interface list and the `## Interface Paths` globs to what this project actually promises and where it keeps it.

```text
rubrics/
├── INDEX.md            # type list, detection signals, scoring and merge rules
├── _template.md        # skeleton for a type the catalog does not cover yet
├── common.md           # SemVer principles that hold across every type
└── <type>.md           # one draft per project type, all on one level
```

- Read `INDEX.md` first. It is the only file that lists the types, so a draft not indexed there is invisible to the scan.
- Every draft ships an `## Interface Paths` table, but its globs are the layout that type conventionally uses, not this repository's. Check them against the real tree before writing, and drop the rows that match nothing. A glob that matches nothing is dead weight; a glob that matches the wrong tree floors the wrong changes.
- Drafts are not grouped into subdirectories. The `consumer` column in `INDEX.md` carries the grouping, because a project often serves several kinds of consumer at once and a directory would force it into one.
- Do not read every body. Read `INDEX.md`, pick the type, read that one file.
- The catalog grades on the SemVer consumer-compatibility axis, not the human-intervention axis the default rubric uses. The two disagree — removing a feature is `major` in the catalog and `minor` in the default. Adopt one whole; never merge questions from both into one rubric.
- The catalog is payload: `jig-update` replaces it. Never edit a catalog file to record a project's decision — the decision lives in the resolved rubric path.

When the project type is not obvious, run `rubric-scan` (or the installed `jig-rubric-scan`) first. It scans the repository, scores it against `INDEX.md`, and hands back a type with the paths that produced it. This skill still owns the write.

## Actions

Called without arguments. Determine the current state first, then confirm the user's intent.

| Action | When | Result |
|---|---|---|
| Review | file exists | Report the current rubric: path, source, kind, the three grades, commit state. Stop. |
| Create | file missing | Show the default, ask the binary question, write the file. |
| Adopt a type | the project has a clear type, or `rubric-scan` handed one over | Write that catalog draft as the rubric, dated and with the interface list and path globs adjusted. |
| Re-set | file exists, user wants a different rubric | Show the current rubric, confirm, then replace it. |
| Edit one grade | file exists, one grade is wrong | Update that grade's question and definition only; preserve the rest. |
| Reset to default | file exists, user wants the default back | Replace with the default rubric and update the `> Basis:` line. |
| Convert titles | file exists with legacy Korean titles and the user asks | Rename only the section titles to the English spellings; leave every question, definition, and rule word for word. |
| Add interface paths | file exists without `## Interface Paths` and the user wants the path floor | Append the table, built from the paths this project's public interface actually lives in. Change nothing else. |

## Procedure

1. Resolve the path and read the file if it exists. Report which of the three sources supplied the path, and note when it came from the environment variable that it is session-only.
2. If the file exists, summarize it and confirm the intent: keep, re-set, edit one grade, or reset to default. Keep ends the run.
3. For create or re-set, show the default rubric and ask one question: **use this rubric?**
   - Yes → write the default and record adoption in the `> Basis:` line.
   - No → offer the catalog before drafting from scratch. Read `rubrics/INDEX.md`, name the types that fit what this repository ships, and let the user pick one; when the type is unclear, run `rubric-scan` and use its recommendation. A chosen draft is written as-is except for the `> Basis:` line, the interface list, and the `## Interface Paths` globs, which are checked against the repository's actual layout.
   - No catalog type fits → ask, for each of the three grades, which changes in this project belong there. Put the user's own wording into `## Decision Order` and `## Grade Definitions`.
4. If the user skips the question or does not answer, adopt the default and record it. Do not ask again.
5. Keep the user's vocabulary, including the language they answered in. Only normalize the sentence shape into `<question> → \`patch\`` form. Translating their words into jig terms such as "silent behavior change" makes the next release grade differently than they intended.
6. Write the file, creating `.jig/` when missing. Then hand the commit to the repository's flow: if `develop-task-flow` (or the installed `jig-develop-task-flow`) exists, follow it with a `chore/<slug>` branch, a `chore:` squash commit, and a `develop` push. Otherwise propose a normal commit on the current branch.
7. Report.

## Safety Rules

- Never overwrite an existing rubric without showing its current content and getting explicit confirmation.
- Do not create `.bak` copies. The file is tracked, so git history is the record. Warn before overwriting when the file is untracked or has uncommitted changes.
- Do not translate or retitle an existing rubric without being asked. The questions are the project's own words.
- Do not grade a release or write release notes; `github-release` owns that.
- Do not touch branches, branch protection, tags, releases, or GitHub settings.
- Do not write anything outside the resolved rubric path and its parent `.jig/` directory.
- Do not modify `rubrics/`. It is shipped payload that `jig-update` replaces; a project's decision belongs in the rubric file.
- Do not force a commit. If the user declines, report the uncommitted state.
- Preserve unrelated user changes.

## Final Report

Write the report in the language the repository already uses for its own documents, defaulting to English.

```md
## Version Rubric

- Path: <path> (source: environment variable | local config | convention)
- Basis: jig default (human-intervention axis) | catalog <type> | project-specific
- Titles: English | Korean (legacy, still read)
- patch: <question>
- minor: <question>
- major: <question>
- Change: created | re-set | <grade> edited | reset to default | none
- Draft source: none | rubrics/<type>.md
- Commit: done <commit subject> | uncommitted (does not reach clones)
- Next: none | <action>
```
