# <Type Name> Version Policy

> Basis: SemVer <type name>, adopted `<date>`

## Public Interface

- <what the people using this project depend on, 1>
- <what they depend on, 2>
- <what they depend on, 3>

<One sentence naming what is not the public interface, and why.>

## Decision Order

1. <Did it fix wrong behavior while keeping the public interface?> → `patch`
2. <Can existing consumers keep going untouched, with only new capability added?> → `minor`
3. <Must existing consumers change something?> → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | <definition> | <2-3 examples> |
| `minor` | <definition> | <2-3 examples> |
| `major` | <definition> | <2-3 examples> |

## Hard Rules

> <a condition that always escalates, regardless of size, 1>

> <condition 2>

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `<glob for what consumers depend on>` | <which promise it carries> | `minor` |
| `<glob for internals>` | internal | `patch` |

## Hotfix Triggers

> Does harm keep occurring and accumulating for as long as the released state stands?

- <observable state this question has already identified, 1>
- <observable state, 2>

## Pre-Release Checks

- <what to verify before releasing, 1>
- <check 2>

## Version Format

- <how this type's version number differs from other numbers around it: store build numbers, API generations, schema versions>
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.

<!--
How to write this file

- `## Decision Order` and `## Grade Definitions` are required; the other six sections are optional. Delete a section this type has nothing to say about.
- `## Hotfix Triggers` holds one anchoring question and the observable states answering it. Write states, not feelings. When nothing matches, `hotfix-flow` puts the question and, on a `yes`, adds the new condition here in its own commit before the fix begins. Keep the question general: domain wording differs by type but the answer does not, so do not rewrite it per type.
- `## Interface Paths` turns `## Public Interface` into globs the grading skills can match against `git diff --name-only`. Rows are read top to bottom and the first match wins, so put specific globs above general ones. The floor it produces is advisory: a release may land below it with a recorded reason.
- Spend the effort on `## Public Interface`, `## Interface Paths`, `## Hard Rules`, and `## Pre-Release Checks`. The decision order and grade definitions only need the three questions from common.md restated with this type's nouns.
- The decision order is asked top down and stops at the first match. That meaning cannot be changed.
- What is graded is consumer compatibility across the release. AI effort, file counts, and implementation time are not grounds.
- `## Hard Rules` holds **only conditions that always escalate**. Statements about what is not grounds for a grade belong in common.md, and version-number notation belongs in `## Version Format`.
- Check that question 1 does not swallow question 2. Putting "was something added?" in question 1 stops every addition at `patch` and makes `minor` unreachable.
- `## Public Interface` applies to projects that ship documents, assets, or data too. If consumers depend on it, it is a public interface even when it is not code.
- Delete this comment block when finished. The body must be able to become `.jig/versioning.md` as-is.
- Finally, add a row to the table in INDEX.md.
-->
