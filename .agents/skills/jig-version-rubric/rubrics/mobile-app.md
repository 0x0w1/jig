# Mobile App Version Policy

> Basis: SemVer mobile app, adopted `<date>`

This is an app installed onto a device through a store. If it opens in a browser, use the `web-client` rubric; if it is a desktop install, use `desktop-app`.

## Public Interface

- The main tasks a user can complete and their default behavior
- Deep links, universal links, app links
- Local data, backup, and sync formats
- Push notification payloads and how they are handled
- The supported version range against the server API
- Supported OS versions, device capabilities, extension and widget contracts
- URL schemes and SDKs exposed to other apps

The internal UI framework and the build system are implementation details unless they change the contract above.

## Decision Order

1. Did it fix app defects while keeping existing flows, data, and integrations? → `patch`
2. Did it only add optional features, screens, or platform support while existing installs and usage held? → `minor`
3. Must existing users change data, settings, OS, integrations, or the way they use the app? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the existing app contract | crash fixed, battery use improved, sync defect fixed |
| `minor` | Features that coexist with existing usage | opt-in feature, new widget, new deep link |
| `major` | A change incompatible with existing installs, data, or integrations | local data needs manual conversion, URL scheme removed, minimum OS raised so existing devices drop out |

## Hard Rules

> When the server stops supporting older app versions, or a forced update becomes necessary, grade the app-to-server compatibility contract as `major`.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/Info.plist`, `**/AndroidManifest.xml`, `**/*.entitlements` | deep links, URL schemes, and OS requirements | `minor` |
| `**/schemas/**`, `**/migrations/**` | local data, backup, and sync formats | `minor` |
| `**/notifications/**`, `**/push/**` | push payloads and how they are handled | `minor` |
| `**/widgets/**`, `**/extensions/**` | extension and widget contracts | `minor` |
| `src/**`, `app/**`, `lib/**` | application internals | `patch` |
| `test/**`, `docs/**` | tests and documentation | `patch` |

## Pre-Release Checks

- Test data upgrade and session retention from the previously published version.
- Contract-test the supported server and app version combinations.
- Verify deep links, notifications, and background tasks in the real distribution build.

## Version Format

- Keep the user-facing SemVer separate from the store build number. Resubmitting for review or rebuilding the same functionality does not raise the SemVer grade.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
