# Configuration Collection Version Policy

> Basis: SemVer configuration collection, adopted `<date>`

## Public Interface

- How it is applied: the install command, symlink locations, copy targets
- The tool behavior, keybindings, and aliases the configuration changes
- Required tools, versions, and operating systems
- Where personal values (name, email, tokens) live and whether those files are tracked
- Branching rules for using it across machines (work/personal, macOS/Linux)

Internal tidying, comments, and file splits are not the public interface as long as the applied result is the same.

## Decision Order

1. Did it tune the values of existing configuration while the way it applies and behaves held? → `patch`
2. Did it add tools, profiles, or per-machine branches while existing configuration held? → `minor`
3. Must it be applied again, does a familiar gesture now do something else, or is a new tool required? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix with the same application method and the same gestures | color tweak, plugin option tidied, comments improved |
| `minor` | Growth that coexists with existing configuration | new tool configured, new alias, per-OS branch added |
| `major` | A change that must be reapplied or that retrains the hands | install path changed, keys rebound, default shell or editor swapped, new required tool |

## Hard Rules

> If the same keybinding starts doing something else, it is `major`. Nothing errors; only the hands are wrong.

> If the location or tracked status of a file holding personal values changes, it is `major`. Leaks and losses ride on it.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `install.sh`, `bootstrap.sh`, `Makefile` | how the configuration is applied | `minor` |
| `**/*.template`, `**/*.example` | where personal values are meant to live | `minor` |
| `**/keybindings.*`, `**/aliases.*` | gestures that already live in someone's hands | `minor` |
| `shell/**`, `editor/**`, `git/**` | tuning of existing configuration values | `patch` |
| `docs/**` | documentation | `patch` |

## Pre-Release Checks

- Run the install procedure from scratch on a clean account or container.
- Reapply on a machine that already has the old configuration and check the overwrite and backup behavior.
- Confirm that no token or password ended up in a tracked file.

## Version Format

- Machines apply at different times, so list "what must be reapplied from this version on" separately in the release notes.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
