# Library and SDK Version Policy

> Basis: SemVer library and SDK, adopted `<date>`

## Public Interface

- Exported functions, classes, types, constants, and module paths
- Signatures, generic constraints, return values, and errors
- Protocol and serialization formats and their defaults
- Extension and plugin hooks
- Supported language, runtime, and compiler versions
- Peer dependencies and transitive types exposed to consumers

Private symbols and the build and test setup are implementation details unless they change the published artifact or the consumer's environment.

## Decision Order

1. Did it fix bugs, performance, or internals while keeping the public API and supported environments? → `patch`
2. Does existing consumer code still compile and run, with only new APIs or features added? → `minor`
3. Must existing consumer code, configuration, runtime, or serialized data change? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the existing API and its meaning | implementation bug fixed, performance improved, internal dependency swapped |
| `minor` | Backward-compatible API growth | new function or type, optional parameter added compatibly |
| `major` | A change that breaks source, binary, or behavior compatibility | export removed, signature changed, meaning of a default changed, runtime support dropped |

## Hard Rules

> If it still compiles but the same call returns a different meaning, throws differently, or has different side effects, it is `major`.

> If adding a union member or enum case breaks an existing consumer's exhaustive check, it is `major`.

## Pre-Release Checks

- Review a public API or ABI diff.
- Run consumer fixtures on the minimum and maximum supported runtime and compiler.
- Test serialization, deserialization, and compatibility with data written by earlier versions.

## Version Format

- Keep the package registry version and the git tag SemVer identical.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
