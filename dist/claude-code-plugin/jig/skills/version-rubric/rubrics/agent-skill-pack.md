# Agent Skill Pack Version Policy

> Basis: SemVer agent skill pack, adopted `<date>`

## Public Interface

- Skill names and how they are invoked (slash command, directory name, prefix)
- The `description` and trigger conditions that decide when each skill fires
- The file paths a skill reads and writes, and the section contract of those files
- The commands a skill runs, the tools it requires, the permissions it needs
- Install location, install command, supported agent targets
- The questions asked of the user and the default response policy

Prompt wording, the order of internal steps, and explanatory text are implementation details as long as the trigger conditions and the outputs stay the same.

## Decision Order

1. Did it only change wording, steps, or documentation while trigger conditions and outputs held? → `patch`
2. Do existing usages still work, with skills, options, or steps added? → `minor`
3. Must an installation edit files, configuration, or call sites, or does the same request now behave differently? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix with identical trigger conditions and outputs | typo, better example, report wording tidied, internal step order tidied |
| `minor` | Growth that coexists with existing usage | new skill, optional step, new target supported |
| `major` | A change an installation must act on | skill name or path changed, file section contract changed, default behavior changed, manual migration required |

## Hard Rules

> A change that raises no error but shifts trigger conditions or the default response is `major`. No test catches it, so the version number is the only channel left.

> If the release notes carry migration guidance an installation must apply by hand, it is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `install.sh`, `install.ps1` | the install command and supported agent targets | `minor` |
| `manifest.tsv` | which skills ship and how they are invoked | `minor` |
| `skills/*/scripts/**` | commands a skill runs on the user's machine | `minor` |
| `skills/*/assets/**` | files a skill installs into a project | `minor` |
| `skills/**` | skill bodies and their wording | `patch` |
| `dist/**`, `docs/**` | generated payload and documentation | `patch` |

## Pre-Release Checks

- Rebuild the distribution payload and run the validation script.
- Confirm that skill names, paths, and frontmatter `name` values match the distributed payload.
- Confirm that updating an existing installation does not overwrite the user's own files.

## Version Format

- The pack version is the contract version of the whole package, not of an individual skill. One skill changing still grades the package.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
