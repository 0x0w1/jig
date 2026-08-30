# Content Site Version Policy

> Basis: SemVer content site, adopted `<date>`

This is a project whose contract is the published pages and their URLs. If nothing is published and the documents in the repository are read directly, use the `document-archive` rubric instead.

## Public Interface

- The URLs of published pages and how long they are kept
- Site structure (menus, sections, index pages) and the paths through it
- Feed addresses (RSS, newsletter) and the shape of their items
- Published languages, translations, and how they map to each other
- Anchors that outside links and citations point at
- Publishing cadence and audience (public, private, subscriber-only)

Themes, colors, fonts, and the build tool are not the public interface as long as URLs and structure hold.

## Decision Order

1. Was something written or corrected while existing URLs and structure held? → `patch`
2. Were existing pages left in place while sections, feeds, languages, or features were added? → `minor`
3. Do URLs change, is navigation reorganized, or does the audience change? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | Content changes inside the existing publishing contract | new post published, typo fixed, image swapped, theme styling adjusted |
| `minor` | Growth that coexists with existing pages | new section or tag index, search added, translation added, feed added |
| `major` | A change that makes readers find things again | URL scheme changed, posts moved or deleted in bulk, menu overhauled, audience narrowed |

## Hard Rules

> If an existing URL 404s with no redirect, it is `major`. With a redirect in place it can come down to `minor`.

> If the claim or conclusion of an already-published post changes, it is `major`. Leaving a correction notice included.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/_redirects`, `netlify.toml`, `vercel.json`, `**/routes.*` | URL retention and redirects | `minor` |
| `**/feed.*`, `**/rss.*`, `**/atom.*` | feed addresses and the shape of their items | `minor` |
| `config/**`, `**/config.*`, `**/menu.*` | site structure, menus, and published languages | `minor` |
| `content/**`, `posts/**`, `pages/**` | writing published under existing URLs | `patch` |
| `themes/**`, `layouts/**`, `assets/**` | presentation | `patch` |

## Pre-Release Checks

- Build, then confirm no internal link or image path broke.
- Confirm redirects exist for deleted and moved pages.
- Confirm that feed items will not be resent to existing subscribers as duplicates.

## Version Format

- Publishing time and the repository version are separate. Posting daily still accumulates `patch` releases as long as the URL contract holds.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
