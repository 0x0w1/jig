# CLI Tool Version Policy

> Basis: SemVer CLI tool, adopted `<date>`

## Public Interface

- Commands, subcommands, options, positional arguments
- Defaults, exit codes, signal handling
- Whatever machines consume out of stdout and stderr, and the `--json` schema
- Config files, environment variables, credential lookup
- Shell completion and the automation contract
- Supported operating systems, shells, and runtimes

Progress text meant only for humans and internal modules are implementation details unless they change the automation contract. That said, human-readable output that the documentation promises as parseable is part of the public interface.

## Decision Order

1. Did it fix defects while keeping existing commands, options, output, and configuration? → `patch`
2. Do existing scripts still run, with only new commands, options, or output modes added? → `minor`
3. Must an existing script or user change how it invokes, parses, or configures the tool? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the existing CLI contract | wrong exit code restored, error handling improved, human-readable wording corrected |
| `minor` | Features that coexist with existing invocations | new subcommand, opt-in flag, new `--json` field |
| `major` | A change incompatible with existing commands or automation | option removed or renamed, default changed, JSON field changed, supported shell dropped |

## Hard Rules

> Even when a deprecated option fails while naming its replacement, if existing automation stops working it is `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/cli/**`, `**/commands/**`, `bin/**` | commands, options, and exit codes | `minor` |
| `completions/**` | shell completion and the automation contract | `minor` |
| `**/schemas/**` | the machine-readable output schema | `minor` |
| `src/**`, `internal/**` | implementation | `patch` |
| `tests/**`, `docs/**`, `man/**` | tests and documentation | `patch` |

## Pre-Release Checks

- Compare representative command fixtures and exit codes against the previous version.
- Review a schema diff of machine-readable output such as `--json`.
- Test the precedence between config files and environment variables.

## Version Format

- Keep the package, the binary, the `--version` output, and the git tag on the same SemVer.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
