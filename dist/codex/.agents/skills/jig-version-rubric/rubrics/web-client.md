# Web Client Version Policy

> Basis: SemVer web client, adopted `<date>`

This is a project whose contract is the screen that opens in a browser and the URLs behind it. If it installs onto a device through a store, use the `mobile-app` rubric; if it is downloaded, installed, and works with local files, use `desktop-app`.

## Public Interface

- The main tasks a user can complete and their default behavior
- Public URLs, routes, bookmarks, deep links
- Compatibility of browser local storage, IndexedDB, and cookies
- External embeds, `postMessage`, and any public JavaScript API
- Supported browsers and the accessibility and keyboard contract
- The supported version range against the server API

Component structure, CSS implementation, and the bundler are implementation details unless they change the contract above.

## Decision Order

1. Did it fix defects while keeping existing user flows, URLs, and stored state? → `patch`
2. Did it only add new screens, optional features, or routes while existing usage held? → `minor`
3. Must existing users change URLs, stored data, automation, or the way they work? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps published web behavior | rendering bug, accessibility defect, performance regression |
| `minor` | Features that coexist with existing flows | new opt-in screen, new filter, new route |
| `major` | A change that breaks existing flows or external integrations | URL removed, stored data must be reset, meaning of a default workflow changed |

## Hard Rules

> If an existing URL still opens but performs a different task, or the meaning of an existing setting quietly changes, it is `major`.

## Pre-Release Checks

- Run an upgrade test against browser state saved by the previous version.
- Smoke-test public routes and deep links.
- Verify the supported browser and server API combinations.

## Version Format

- Deployment count and SemVer releases need not match. Tag the compatibility unit that is exposed to users.
- Even when deployment is automatic and users cannot choose a version, do not skip the compatibility grade. The less reversible the deployment, the more the grade is the only record.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
