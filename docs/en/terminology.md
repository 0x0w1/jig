# jig Terminology

[한국어](../ko/terminology.md) · [Documentation home](index.md)

Use these terms whenever scope changes what should be implemented or distributed.

## jig product

The behavior and payload delivered to users. This includes installed skills, installer and update behavior, generated `dist/`, plugin hooks, and state the product creates in installed repositories.

A **jig product change** may affect Claude Code, Codex, Antigravity, releases, migrations, or existing installations. It normally requires the source skill copies and distribution to remain synchronized.

## jig source repository

This repository, where the jig product is developed. Repo-local agent instructions, validation, project plans, documentation maintenance, and contributor tooling belong here unless they are deliberately added to the product payload.

A **jig source repository rule** governs work on jig itself and does not automatically become a feature supported in installed projects.

## jig-managed project

An external repository where jig is installed and used. Clone-local hooks, `.jig/` files, local Git configuration, branch state, and GitHub settings are jig-managed project state.

## Naming rule

Avoid “this project” and “the current project” when the intended scope affects implementation. Name the scope explicitly:

- **jig product feature**: shipped to users
- **jig source repository rule**: used only while developing jig
- **jig-managed project state**: created or inspected in an installed repository
