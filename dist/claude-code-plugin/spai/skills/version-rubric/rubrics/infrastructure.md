# Infrastructure Version Policy

> Basis: SemVer infrastructure, adopted `<date>`

## Public Interface

- Module, chart, and template inputs, outputs, variables, and defaults
- The names of created resources and the reference points others use
- The state, import, and upgrade contract
- Network, identity, secret, and storage boundaries
- Supported providers, platforms, regions, and tool versions
- Availability, backup, retention, and recovery guarantees
- The deployment and operational procedure consuming projects must follow

How resources are composed internally is an implementation detail unless it affects the cost, availability, security, or operational contract.

## Decision Order

1. Did it fix defects, cost, or performance while keeping existing inputs, state, and operational contracts? → `patch`
2. Did it only add optional resources, variables, or outputs while the result of applying it stayed the same? → `minor`
3. Must existing consumers change state, configuration, permissions, or procedures, or accept downtime? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the existing infrastructure contract | wrong policy fixed, missing tag restored, zero-downtime performance work |
| `minor` | Opt-in growth that coexists with existing setups | optional resource, variable, or output added |
| `major` | A change incompatible with state, resources, or operations | variable removed, resource address changed, manual import needed, downtime required, supported provider dropped |

## Hard Rules

> Even when the plan succeeds, replacing or destroying existing resources unexpectedly, or changing what security and availability mean, is `major`.

> If consumers take on required cost or operational responsibility beyond the existing contract, it is `major`. Cost going up or down is not by itself grounds for a grade.

## Pre-Release Checks

- Run the new version's plan against state created by the previous version and inspect replacements and deletions.
- Test the minimum and maximum supported provider and tool versions.
- Verify backup, migration, rollback, and disaster-recovery procedures.

## Version Format

- Keep the version of the consumable artifact (module, chart) separate from the deployed environment's revision.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
