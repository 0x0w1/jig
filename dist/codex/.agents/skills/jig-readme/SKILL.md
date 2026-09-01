---
name: jig-readme
description: "Use when writing or updating a project README.md: scan the repository to classify the project type (CLI tool, library, service or app), draft a new README when none exists, or compare the existing README's claims (commands, options, paths, links) against the repository and fix the drift. Keeps the README short by moving facts stated in more than one place into the detail docs, and proposes that move before making it. Writes only verified facts; keeps the existing README language and defaults to the language the repository already writes in for new files."
---

# README

Use this skill to create or update the repository's `README.md` from the actual repository state.

## Procedure

1. Scan the repository:
   - Manifest and build files: `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Makefile`, lock files.
   - Entry points, CLI argument definitions, scripts, and service configs (`Dockerfile`, `docker-compose*.yml`).
   - Existing documentation under `docs/` and usage examples in the code.
2. Classify the project type: **CLI tool**, **library**, **service/app**, or **other**. The type selects the section layout below.
3. Branch on the current state:
   - No `README.md` → **create path**: draft the README with the section layout below.
   - `README.md` exists → **update path**: check every verifiable claim in the README — commands, options, file paths, links, feature statements — against the repository. Collect mismatches into a drift list, report the list, then apply the fixes. Leave sections that are still accurate untouched.
4. Apply the accuracy rules to every line written.
5. Run the compression pass from the Compression Rules below:
   - Create path: apply it while drafting. Nothing was published yet, so there is nothing to propose.
   - Update path: collect the duplication and overstatement into a proposal — name each fact, where it is repeated, and which detail doc would hold it — then ask before moving anything. Report the proposal even when the user declines it.
6. Merge the change:
   - When the repository has the `develop-task-flow` skill (or the installed `jig-develop-task-flow`), follow it: a `chore/<slug>` branch, a squash merge with a `docs:` commit, then push `develop`.
   - Otherwise propose a normal commit on the current branch.

## Section Layout

Required sections, in order:

1. Title plus a one-line description.
2. Introduction: what the project does and why it exists.
3. Installation.
4. Usage.

Additions by project type:

- CLI tool: a command and option table.
- Library: an API summary with example code.
- Service/app: how to run it (dev and prod) and the required environment variables.

Optional: documentation links, license.

## Layout Rules

- A table is fine for identifiers people copy — skill names, commands, options, paths. What breaks such a name is the **width ratio between columns**: GitHub sizes columns by content, so a description column several times longer than the identifier column squeezes the identifier until it wraps mid-name, and the reader sees a name that does not exist.
- Keep description cells roughly as short as the identifiers, about one clause. When descriptions run long, either trim them or move the whole thing to a list: `- **\`name\`** — description`.
- Wrapping inside a description is expected and needs no work.

## Compression Rules

A README is read before the reader has decided to use the project. Everything in it competes for that attention, so length is a symptom: a long README is almost always one fact written in several places, not one project with a lot to say.

**Move, do not delete.** When the same fact appears in more than one place, keep it in the one place a reader arrives at first and move the rest into the detail doc that already covers it, creating that doc only if none exists. Nothing is lost; the README stops repeating itself. There is no line count to hit — a library README with the API examples it genuinely needs is not too long, and a short README that says the same thing twice is still wrong.

**Lead with what the reader gets.** The introduction says what becomes easier, not which features exist. `records a graded release trailer at merge` is a feature; `you stop reconstructing why a version was a minor` is what the reader gets. Order the claims by how strong the evidence is, strongest first, and make any surrounding prose list them in that same order — a paragraph and its bullets must not imply different priorities.

**Claim only what the repository can back, and say when it applies.** A claim the repository cannot demonstrate is left out, not softened. State the condition under which the value appears, so a reader outside that condition can rule the project out quickly rather than discovering it later.

**Cut what is not read before installing.** Roadmaps, design records, and direction notes are things the project keeps for itself. Link them from the documentation home, not from the README.

**Fold contributor material.** Build, regeneration, and validation commands serve people who already cloned the repository. Put them in a `<details>` block or a contributing doc.

**Merge blocks that differ by one value.** Separate command blocks per platform or target that vary only in an argument become one block with that argument named.

**Give the reader a way past the top.** When the README has more than about four sections, put a one-line link row under the title so a returning reader jumps straight to the section they came for.

## Accuracy Rules

- Write only install and run commands verified against the repository: a script, manifest, or lock file must show them.
- Verify that every linked file path exists.
- Do not describe features, badges, or integrations the repository does not contain.
- When a claim cannot be verified, leave it out and report it instead.

## Language Rules

- An existing README keeps its language.
- A new README is written in the language the repository already uses for its documents, defaulting to English, with technical terms in backticks.
- An explicit language request from the user overrides both.

## Report

- Project type and the path taken (create or update).
- On the update path: the drift list and what was fixed.
- The compression proposal: each fact repeated in more than one place, where it would move, and whether the user accepted it.
- Claims that could not be verified and were left out.
