# Dataset Version Policy

> Basis: SemVer dataset, adopted `<date>`

This is a repository that ships the cleaned data files themselves. If the contract is the process that produces the data and its refresh cadence, use the `data-pipeline` rubric instead.

## Public Interface

- File paths, names, formats, encodings, and delimiters
- Column names, types, units, allowed values, and how missing data is marked
- What one row counts (the observation unit) and the deduplication rule
- Collection scope (period, region, subject) and refresh cadence
- Provenance, whether values are derived, personal-data and audience limits
- Whether files from earlier versions are retained

The internal collection procedure and cleanup scripts are not the public interface as long as the file and column contract holds.

## Decision Order

1. Were errors fixed, or a regular refresh added to existing files, while column and value meanings held? → `patch`
2. Were columns, files, or periods added while existing columns held? → `minor`
3. Must the reading side change column mappings, interpretation, or aggregation? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | Data refreshed or corrected inside the existing contract | mistyped value fixed, scheduled refresh added, documentation expanded |
| `minor` | Growth with no effect on existing consumers | new column, new year's file, alternative format offered |
| `major` | A change incompatible with existing interpretation | column dropped or renamed, unit or currency changed, observation unit changed, historical data recomputed, audience narrowed |

## Hard Rules

> If the file still reads but the unit or basis of a value differs, it is `major`. Aggregates change quietly.

> Recomputing an already-published historical range and overwriting it is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/schema.*`, `**/codebook.*`, `**/*.dictionary.*` | column types, units, and allowed values | `minor` |
| `LICENSE*`, `DATASHEET*`, `**/PROVENANCE*` | provenance, audience, and use limits | `minor` |
| `data/**` | published files and the values in them | `patch` |
| `scripts/**`, `notebooks/**`, `docs/**` | collection procedure and documentation | `patch` |

## Pre-Release Checks

- Diff the column list and types against the previous version.
- Compare row counts and key totals against the previous version to catch unexpected shifts.
- Run checks for missing values, duplicates, and out-of-range values.

## Version Format

- The collection date and the repository version are separate. A date in a filename is the data's range; the version is what the reading side pays.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
