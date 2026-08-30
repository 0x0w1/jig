# Data Pipeline Version Policy

> Basis: SemVer data pipeline, adopted `<date>`

This is a project that builds data on a schedule and pushes it downstream. A repository that ships an already-built set of files as-is uses the `dataset` rubric instead.

## Public Interface

- Names, locations, schemas, and column meanings of the tables and files produced
- Units, time zones, currencies, precision, and null conventions of the values
- Aggregation basis: the grain, the deduplication rule, the metric definitions
- Refresh cadence, latency guarantees, reprocessing and backfill policy
- What is required of the input sources
- Partition and snapshot conventions downstream consumers reference

Transformation logic, engines, and scheduler configuration are not the public interface as long as the meaning and arrival time of the output hold.

## Decision Order

1. Did it fix defects or performance while keeping the output schema and the meaning of values? → `patch`
2. Did it only add tables, columns, or metrics while existing columns and values stayed the same? → `minor`
3. Must downstream consumers change queries, reports, interpretation, or reprocessing? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the output contract | missing records recovered, wrong join fixed, runtime shortened |
| `minor` | Growth with no effect on existing consumers | new table, nullable column added, new source added |
| `major` | A change incompatible with existing output | column dropped or retyped, metric definition changed, grain changed, refresh cadence reduced |

## Hard Rules

> A change where the query still succeeds but the numbers differ is `major`. Editing a metric definition is exactly this.

> Recomputing historical data so that already-published reports change value is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/models/staging/**`, `**/intermediate/**` | intermediate steps no consumer reads | `patch` |
| `**/models/**`, `**/marts/**`, `**/transforms/**` | the tables produced and their column meanings | `minor` |
| `**/schema.*`, `**/contracts/**` | output schemas and null conventions | `minor` |
| `**/dags/**`, `**/schedules/**` | refresh cadence and latency guarantees | `minor` |
| `tests/**`, `docs/**` | tests and documentation | `patch` |

## Pre-Release Checks

- Run the old and new versions on the same input and compare row counts and metric differences.
- Confirm that no column referenced by downstream dashboards or models was dropped or retyped.
- Confirm the backfill range and the cost of reprocessing.

## Version Format

- The pipeline version and the data schema version are separate. The pipeline can be `major` while the schema holds, and a new schema version can be offered alongside in a `minor` release.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
