---
name: readme
description: "Use when writing or updating a project README.md: scan the repository to classify the project type (CLI tool, library, service or app), draft a new README when none exists, or compare the existing README's claims (commands, options, paths, links) against the repository and fix the drift. Writes only verified facts; keeps the existing README language and defaults to Korean for new files."
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
5. Merge the change:
   - When the repository has the `develop-task-flow` skill (or the installed `spai-develop-task-flow`), follow it: a `chore/<slug>` branch, a squash merge with a `docs:` commit, then push `develop`.
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

## Accuracy Rules

- Write only install and run commands verified against the repository: a script, manifest, or lock file must show them.
- Verify that every linked file path exists.
- Do not describe features, badges, or integrations the repository does not contain.
- When a claim cannot be verified, leave it out and report it instead.

## Language Rules

- An existing README keeps its language.
- A new README is written in Korean with technical terms in backticks.
- An explicit language request from the user overrides both.

## Report

- Project type and the path taken (create or update).
- On the update path: the drift list and what was fixed.
- Claims that could not be verified and were left out.
