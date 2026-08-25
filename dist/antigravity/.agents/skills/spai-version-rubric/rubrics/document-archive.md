# Document Archive Version Policy

> Basis: SemVer document archive, adopted `<date>`

This is a repository where the document files themselves are looked up and read. If it is published as a site and URLs become the contract, use the `content-site` rubric instead.

## Public Interface

- Where documents live, what they are named, and the links that point at them
- The classification scheme (directories, categories, tags) and what it means
- The scope of the question each document answers
- The force of the rules and procedures a document states, and when they take effect
- Document templates, required fields, and approval markings
- The rule for telling which document is current

Spelling fixes, smoother sentences, and better examples do not change the public interface, because readers can keep doing exactly what they did.

## Decision Order

1. Were documents added, edited, or removed while their location, classification, and force stayed the same? → `patch`
2. Were existing documents left alone while the way they are managed (templates, automation, search or publishing tooling) was added to or improved? → `minor`
3. Do links break, does the classification change, or does what people must follow change? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | Document content added, edited, or removed | new manual written, stale explanation refreshed, retired document cleared out |
| `minor` | A change to the tools, templates, or rules for producing and managing documents | new template, generated table of contents, naming convention added |
| `major` | A change to how documents are found or what people must follow | directories reorganized, categories merged, a rule's force changed, files renamed in bulk |

## Hard Rules

> If a link someone set from outside breaks, it is `major`. Moving a file or renaming it counts.

> If what a person must do changes in a rules or procedure document, it is `major` even when only one line moved.

## Pre-Release Checks

- Confirm that every relative link between documents still resolves.
- List the files moved or renamed in this release and put that list in the release notes.
- Where a rule's force changed, state the effective date inside the document.

## Version Format

- A document's own revision history and the repository version are separate. "Revision 3" inside a document is that document's history; the repository version says what this release asks of its readers.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
