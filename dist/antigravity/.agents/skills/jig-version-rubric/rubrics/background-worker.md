# Background Worker Version Policy

> Basis: SemVer background worker, adopted `<date>`

## Public Interface

- Queue, stream, and event message schemas and their meaning
- Topics, routing keys, partition keys
- Retry, timeout, dead-letter, and idempotency policy
- Processing order and delivery guarantees
- Side effects written to databases and external systems
- The supported version range for producers and consumers
- Metrics, alerts, and replay procedures operators rely on

The internal concurrency model and the worker framework are implementation details unless they change the processing contract.

## Decision Order

1. Did it fix defects while keeping existing messages, results, and operational contracts? → `patch`
2. Did it only add optional messages, handlers, or metrics while existing producers and consumers keep working? → `minor`
3. Must existing producers, consumers, data, or operational procedures change? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the processing contract | duplicate-processing bug fixed, throughput improved, retry behavior restored |
| `minor` | Growth that coexists with the existing message flow | new event type, optional field, opt-in handler |
| `major` | A change incompatible with messages, ordering, or side effects | required field added, topic moved, idempotency key changed, delivery semantics changed |

## Hard Rules

> If the same message still processes successfully but the data side effect or the delivery guarantee differs, it is `major`.

> If replaying the backlog produces a different result than before, or manual data cleanup is required, it is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/schemas/**`, `**/*.proto`, `**/*.avsc` | message schemas producers and consumers share | `minor` |
| `**/consumers/**`, `**/handlers/**`, `**/tasks/**` | processing order, side effects, and idempotency | `minor` |
| `config/**` | topics, routing keys, retry, and dead-letter policy | `minor` |
| `src/**`, `internal/**` | worker internals | `patch` |
| `tests/**`, `docs/**` | tests and documentation | `patch` |

## Pre-Release Checks

- Test old producer with new consumer, and new producer with every supported consumer.
- Run contract tests for duplicate, delayed, out-of-order, and failing messages.
- Check backlog replay, dead-letter recovery, and rollback impact.

## Version Format

- Keep the deployment revision separate from the SemVer of the public contract.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
