# Desktop App Version Policy

> Basis: SemVer desktop app, adopted `<date>`

This is an app installed on a user's machine that works with local files, settings, and OS integration. If it opens in a browser, use the `web-client` rubric; if it ships through a store, use `mobile-app`.

## Public Interface

- The tasks a user can complete and their default behavior
- Document, project, and settings file formats
- Where data is stored and how it migrates
- Protocol URLs, file associations, shell integration
- The plugin and extension API
- Auto-update channels and their compatibility
- Supported operating systems, CPU architectures, and system requirements

The internal UI toolkit and packaging tools are implementation details unless they change the install, data, or integration contract.

## Decision Order

1. Did it fix defects while keeping existing files, settings, integrations, and flows? → `patch`
2. Did it only add optional features, formats, or integrations while existing installs and files stayed supported? → `minor`
3. Must existing users change files, settings, plugins, OS, or the way they install? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the existing desktop contract | crash fixed, rendering defect fixed, updater stabilized |
| `minor` | Features that coexist with the existing environment | new export format, opt-in integration, new OS supported |
| `major` | A change incompatible with existing installs, data, or extensions | file format incompatible, plugin API removed, supported OS or architecture dropped |

## Hard Rules

> If the app still opens existing files but quietly saves them in a format the previous version cannot reopen, it is `major`.

> If a code signing, permission, or install-location change requires manual action from the user, it is `major`.

## Pre-Release Checks

- Run an upgrade test with the previous version's files, settings, and plugins.
- Verify the auto-update and rollback paths on every supported OS.
- Verify file associations and protocol handlers from an actual install.

## Version Format

- Map auto-update channels to SemVer prerelease identifiers consistently.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
