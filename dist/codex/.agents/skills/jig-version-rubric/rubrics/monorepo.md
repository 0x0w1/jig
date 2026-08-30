# Monorepo Version Policy

> Basis: SemVer monorepo, adopted `<date>`

Being a monorepo does not by itself decide a versioning strategy. Choose one explicitly — fixed, independent, or mixed — based on how the published products and packages are consumed.

## Public Interface

- The public contract each package, service, or app defines in its own type document
- Dependencies between workspace packages and their supported version ranges
- Shared schemas, protocols, and generated clients
- The cross-package compatibility that a combined deployment guarantees
- Root commands and the build and release entrypoints

## Version Strategy

### Fixed version

Every artifact ships as one product and always carries the same version.

- Grade each package, then apply the highest grade to the whole product version.
- Packages that did not change may still be published at the new version.
- Fits when server and client are a single compatibility unit.

### Independent versions

Each package has its own consumers and release cadence.

- Raise SemVer only for the packages affected.
- Grade separately how a dependency range change affects the consuming package's public contract.
- Keep no product version at the root, or keep only a release manifest.

### Mixed versions

Product groups ship on a fixed version while standalone tools and libraries carry their own.

- List the version groups in the documentation.
- Inside a group use the highest grade; between groups grade independently.
- Moving a package between groups is graded on the compatibility of consumers' install and call sites.

## Decision Order

1. Did it fix defects or internals while keeping the affected version unit's public contract? → `patch`
2. Did it add only backward-compatible capability while existing consumers and package combinations held? → `minor`
3. Must existing consumers or workspace packages change code, configuration, dependencies, or deployment order? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the version unit's public contract | internal package refactor, compatible bug fix |
| `minor` | Capability that coexists with existing package combinations | new package, backward-compatible API added, optional integration |
| `major` | A change that breaks a consumer or a contract between packages | package removed, export changed, dependency range incompatible, deployment order now required |

## Hard Rules

> If a generated client and its schema change together so the repository builds but an external consumer breaks, it is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `packages/*/src/public/**`, `**/schemas/**`, `**/*.proto` | shared schemas and generated clients | `minor` |
| `packages/*/package.json`, `packages/*/*.toml` | workspace dependency ranges and published names | `minor` |
| `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `Makefile` | root commands and release entrypoints | `minor` |
| `packages/*/src/**` | package internals | `patch` |
| `tests/**`, `docs/**` | tests and documentation | `patch` |

## Pre-Release Checks

- Run the tests of the changed packages and of the packages that depend on them.
- Contract-test the supported combinations of old and new package versions.
- Confirm that the actual publish targets, dependency ranges, changelog, and tags match the chosen strategy.

## Version Format

- Pick a tag convention that cannot collide: `vX.Y.Z` for fixed versions, `<package>@X.Y.Z` for independent ones.
- Keep one source of truth for version groups and each package's current version.
- A `major` grade in `0.x` raises the minor position of that version unit, while the grade is still recorded as `major`.
