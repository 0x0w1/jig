# Version Rubric

[한국어](../ko/version-rubric.md)

How jig grades a release as `patch`, `minor`, or `major` is **the project's decision.** That decision lives in one file in the repository, and `github-release` reads it at release time.

The axis differs per project. The default splits on whether a human has to step in; a document-management project splits by the kind of artifact. These are different axes, not different thresholds on one axis, so the rubric was pushed out of the skill and into the project.

Per-type drafts ship with the skill in a **rubric catalog**, so nothing has to be written from scratch. When the type is unclear, `rubric-scan` scans the repository and picks candidates. Both are described under [rubric catalog](#rubric-catalog).

## Where the File Lives

```text
.jig/
└── versioning.md
```

- `.jig/` is **owned by the project.** The installer and `jig-update` never write or delete it, and `jig-doctor` never treats its contents as drift. What you edited is the answer.
- The file **must be committed.** Uncommitted, it does not reach clones or CI, so different people grade differently. `jig-doctor` warns when it is uncommitted.
- Do not put it in `.gitignore`.

## Rubric Catalog

The per-type drafts install inside the `version-rubric` skill payload. Where they land depends on the CLI.

| Environment | Catalog path |
|---|---|
| Claude Code | `${CLAUDE_PLUGIN_ROOT}/skills/version-rubric/rubrics` |
| Codex, Antigravity (project) | `.agents/skills/jig-version-rubric/rubrics` |
| The jig repository itself | [`skills/version-rubric/rubrics`](../../skills/version-rubric/rubrics/INDEX.md) |

```text
rubrics/
├── INDEX.md         # the type list and detection signals. The scan reads only this file
├── _template.md     # skeleton for a type the catalog does not cover
├── common.md        # SemVer principles that hold across every type
└── <type>.md        # 17 per-type drafts, all on one level, no grouping directories
```

Type documents stay flat. The `Consumer` column in `INDEX.md` does the grouping, because one project often serves several kinds of consumer at once. A directory split pushes such a project into one side and moves the path whenever its character changes.

| What reaches the consumer | Types |
|---|---|
| Called and executed | `api-server`, `background-worker`, `data-pipeline` |
| Installed screens | `web-client`, `mobile-app`, `desktop-app` |
| Code others pull in | `library-sdk`, `cli-tool`, `agent-skill-pack` |
| Things that change an environment | `infrastructure`, `config-collection` |
| A wrapper around many packages | `monorepo` |
| Things people read and watch | `document-archive`, `content-site`, `course-material` |
| Assets and data others pull in | `design-assets`, `dataset` |

Whether a developer built the project has no bearing on the grade. A documents-only repository maintained by a developer is still `document-archive`, and a repository maintained by a designer that ships an API is still `api-server`.

### The Catalog and the Default Grade on Different Axes

The 17 catalog drafts grade on the **SemVer consumer-compatibility axis**. The [default rubric](#the-default-rubric-human-intervention-axis) below grades on the **human-intervention axis**. The two read the same change differently.

| Change | Catalog | Default |
|---|---|---|
| A feature or endpoint removed | `major` | `minor` |
| Generation replaced, contract intact | `patch` | `minor` |
| Silent behavior change | `major` | `major` |

Use one or the other. Mixing the questions blurs where the decision order stops. A project with clear outside consumers — installs, callers, readers — fits the catalog; a project whose only consumer is itself, or whose consumers are not settled yet, fits the default.

A catalog file is written so it can become `.jig/versioning.md` as-is. Copy it, then adjust only the date on the `> Basis:` line and the `## Public Interface` list. The catalog itself is payload that `jig-update` refreshes — the project's decision belongs in the rubric file, never in the catalog.

### Type Scan

The `rubric-scan` skill reads the repository and picks candidate types. It is `/jig:rubric-scan` on Claude Code and `jig-rubric-scan` on Codex and Antigravity.

1. It reads the tracked file list, the extension mix, dependency manifests, distribution configuration, and commit history.
2. It scores against the signal table in `INDEX.md` — a strong signal is 2 points, a weak one 1 point, and anything under 3 points is dropped.
3. It reports up to 3 candidates **together with the actual paths that produced the score.** It never recommends without evidence.
4. When you pick a type, the draft is handed to `version-rubric`. That skill writes the file; the scan writes nothing.

Several consumers mean several types. Rather than picking one, merge the other types' `## Public Interface` items into the primary draft, and when one change grades differently per interface, use the highest grade.

### Adding a Type

For a project the catalog does not cover, copy `_template.md` to `<id>.md` on the same level and add a row to the `INDEX.md` table next to rows with a similar consumer. **A file missing from the table is invisible to the scan.** A strong signal must be a path that appears only in that type — files that exist everywhere, such as `README.md`, are not signals.

## Settings

| Key | Kind | Default | Reaches clones | Purpose |
|---|---|---|---|---|
| `JIG_VERSION_RUBRIC` | environment variable | none | no (session only) | one-off path override, CI |
| `jig.versionRubric` | `git config --local` | none | no | repository override when the conventional path cannot be used |
| (conventional path) | file | `.jig/versioning.md` | yes | the normal path |

Resolution order is environment variable → local config → conventional path, the same shape as the `JIG_GITHUB_PROFILE`/`jig.githubProfile` pair.

A config key holds **a path only.** State such as "the default was adopted" belongs on the `> Basis:` line at the top of the file. `git config --local` lives in `.git/config` and does not reach clones, so state kept there makes one repository grade differently for different people.

## Using It

Run `/jig:version-rubric` on Claude Code, `jig-version-rubric` on Codex and Antigravity. No arguments. The skill checks the current state first, then asks what to do.

| What you want | What the skill does |
|---|---|
| See the current rubric | Reports the path, source, kind, the three grades, and commit state |
| Settle it for the first time | Shows the default and asks one question: use this rubric? |
| Find out which type fits | `rubric-scan` scans and picks candidates; this skill writes the chosen draft |
| **Re-settle it** | Shows the current rubric, takes confirmation, then replaces it |
| Fix one grade | Changes that grade's question and definition only, preserving the rest |
| Go back to the default | Replaces it with the full default rubric |

Run it whenever. A rubric changing as a project grows is normal, and editing the file by hand is fine — what you edited is the new rubric.

Right after installation, `jig-setup` calls this skill for you. If the file is missing at release time, `github-release` calls it and then continues the release. Skipping the question records the default as adopted and it is not asked again.

## The Default Rubric (Human-Intervention Axis)

The full text the skill writes. Why the section titles are English is in [section titles](#section-titles).

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

It splits grades by **whether a human has to step in**, not by the size of the change. Projects built with AI turn generations over quickly, and grading by size makes every generation a `major` until the number carries no information. A generation change drops to `minor`, and `major` is reserved for the value on offer widening, shrinking, or changing, or for work a human must do by hand.

Two hard rules come with it. Prompts and instructions are not verified by tests, so one reworded line can quietly change when an agent speaks and CI will not catch it. The version number is what announces a silent behavior change.

While the project is on `0.x`, `minor` and `major` land on the same position (`v0.(Y+1).0`), so these rules do not move the number yet. Not being 1.0 already means "this can change at any time"; the rules start to bind at `v1.0.0`. Delete both sections if you do not want them — the contract makes both optional.

## The File Contract

Two required sections, five optional. **The section titles are the contract.**

| Section | Required | Contents |
|---|---|---|
| `## Decision Order` | required | three questions asked in order, each with its grade |
| `## Grade Definitions` | required | the per-grade definition table |
| `## Hard Rules` | optional | conditions that always escalate |
| `## Interface Paths` | optional | changed paths that set a starting grade |
| `## Release Notes` | optional | override for note section order and titles |
| `## Version Format` | optional | tag pattern, pre-1.0 handling, summary language |
| `## Pre-Release Checks` | optional | commands to run before releasing |

- `## Decision Order` is asked in order and **stops at the first match.** A rubric file cannot change that meaning.
- An optional section the file omits does not apply to that project. Deleting `## Hard Rules` means there is no escalation rule; the default's rules do not step in.

### Interface Paths

`## Interface Paths` is the one optional section that is read by a command rather than by a person. Where a prose list of the public interface leaves the grading skills to judge by eye whether a change touched it, this table lets them compute a starting grade from `git diff --name-only`.

```md
## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `src/api/**` | the HTTP surface consumers call | `minor` |
| `docs/**` | internal | `patch` |
```

- A changed path takes the floor of the **first row it matches**, so specific globs go above general ones. The floor for a range is the highest one any changed path took, and a path matching no row contributes nothing.
- **The floor is advisory.** Paths say what changed, never how, so a typo fix and a broken promise under the same glob match the same row. A release may land below the floor as long as it records why; landing above it needs no justification.
- That is the opposite of the `Release-Grade` trailer `develop-task-flow` writes, which was a judgement made with the diff in hand and is never lowered. Both appear separately in the release report.
- Omit the section and nothing changes: the release grades exactly as it did before.

### Section Titles

The contract titles are English. The skills are written in English throughout, so Korean-only titles would split the vocabulary inside one file and leave every installation deciding which spelling to use.

**A rubric already written with Korean titles keeps working.** Every skill that reads a rubric — `github-release`, `jig-doctor`, `version-rubric`, `rubric-scan` — accepts both spellings.

| English (canonical) | Korean (legacy) |
|---|---|
| `## Decision Order` | `## 판정 순서` |
| `## Grade Definitions` | `## 등급 정의` |
| `## Hard Rules` | `## 강경 규칙` |
| `## Interface Paths` | `## 인터페이스 경로` |
| `## Release Notes` | `## 릴리즈 노트` |
| `## Version Format` | `## 버전 형식` |
| `## Pre-Release Checks` | `## 릴리즈 전 검증` |
| `> Basis:` | `> 기준:` |

- **Do not mix the two spellings in one file.** `## Decision Order` alongside `## 등급 정의` reads as one required section missing.
- A skill never retitles an existing file on its own. To convert, ask `version-rubric` to switch the titles to English; it swaps the titles and leaves every question untouched.
- **Write the questions and definitions in the project's own language.** Only the titles are the contract; inside them, the words of the people reading that repository are the right ones.
- Sections outside the contract are fine. They are read as grading context — a list of what counts as this project's public interface, for instance.
- When a required section is missing under both spellings, or the decision order has fewer than three steps, `github-release` stops the release and points at this skill. Stopping beats grading quietly against a broken rubric.

## Release Note Sections

Note sections derive from the commit prefix automatically. Nothing to configure.

| Commit prefix | Section |
|---|---|
| `feat:` | `🚀 Enhancements` |
| `fix:` | `🐛 Fixes` |
| `chore:` | `🧰 Chores` |
| any other prefix | a section of its own name (`docs:` → `📚 Documentation`) |

In a documentation-heavy project, `docs:` commits do not get pushed into a "chores" bucket. To change the order or titles, write them in the `## Release Notes` section.

## Worked Examples

### A development project

Use the default as-is. Fixes inside the existing feature set are `patch`; adding, removing, or changing capability and replacing a generation are `minor`; the value on offer changing, or a human having to step in, is `major`.

### A document-management project

`document-archive.md` in the catalog covers this. Written by hand it looks like this.

```md
# Version Policy

> Basis: written for this project, <date>

## Decision Order
1. Were documents added, edited, or removed? → `patch`
2. Did the tooling that manages the documents change? → `minor`
3. Was the whole structure reorganized? → `major`

## Grade Definitions
| bump | definition |
|---|---|
| `patch` | Document content changes, including additions and deletions |
| `minor` | Changes to the tools, templates, or scripts that produce and manage documents |
| `major` | A full reorganization of directories, classification, or how things are published |
```

### A tool with installations

jig itself is this case; see [`.jig/versioning.md`](../../.jig/versioning.md). Its axis is "what an installation pays", and it carries two hard rules different from the default ("a silent behavior change is `major`", "any `migration-manual` block makes it `major`") along with a public interface list.

## Related

- [Rubric catalog index](../../skills/version-rubric/rubrics/INDEX.md)
- [Common SemVer principles](../../skills/version-rubric/rubrics/common.md)
- [jig versioning policy](versioning.md)
- [Installation guide](installation.md)
