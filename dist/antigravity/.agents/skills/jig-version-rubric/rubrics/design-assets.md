# Design Asset Version Policy

> Basis: SemVer design assets, adopted `<date>`

## Public Interface

- Asset paths and names, and the code and documents that reference them
- Delivered formats and size variants (`svg`, `png@2x`, the icon grid)
- Design token names and values (color, spacing, type)
- What an asset means: the action an icon stands for, the state a color signals
- Terms of use: license, logo restrictions, minimum clear space
- Component and symbol names and where the library is published

Layer structure in the source editing file and the way it is produced are not the public interface as long as the exported asset is the same.

## Decision Order

1. Was an existing asset refined while its name, format, and meaning held? → `patch`
2. Were existing assets left in place while new assets, variants, formats, or tokens were added? → `minor`
3. Must the referencing side fix a path, a name, or a value, or re-check a screen? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | Asset fixes that leave references untouched | icon pixel alignment, spacing tidied, file size optimized |
| `minor` | Growth that coexists with existing assets | new icon, dark-mode variant, new export format, new token |
| `major` | A change to references, meaning, or terms | file renamed or moved, icon meaning changed, token value changed, logo replaced, license changed |

## Hard Rules

> If an asset with the same name becomes a different drawing or a different color, it is `major`. The reference still resolves while the screen changes.

> If brand rules (logo conditions, license) change, it is `major` even when no asset file moved.

## Pre-Release Checks

- List the files renamed or moved in this release and check the repositories that reference them.
- Diff token value changes against the previous version.
- Confirm the export exists in every declared format and resolution.

## Version Format

- The design library's version and the version of the products consuming it are separate. A `major` here can be a `minor` amount of work in a product.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
