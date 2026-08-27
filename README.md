# jig

<p align="center">
  <img src="resources/branding/colorways/jig-logo-cyan-cerulean-amber.png" width="160" alt="jig project logo: two cyan cerulean guides align varied inputs toward one amber result">
</p>

<p align="center">
  <a href="https://github.com/0x0w1/jig/releases/latest"><img src="https://img.shields.io/github/v/release/0x0w1/jig?style=flat-square&amp;color=009BBF" alt="Latest release"></a>
  <a href="https://github.com/0x0w1/jig/blob/main/LICENSE"><img src="https://img.shields.io/github/license/0x0w1/jig?style=flat-square&amp;color=F2B134" alt="MIT License"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/agents-Claude_Code%20%7C%20Codex%20%7C%20Antigravity-009BBF?style=flat-square" alt="Supported agents: Claude Code, Codex, and Antigravity"></a>
</p>

**same cut, every project** — a jig holds the work so every cut lands the same. This one holds your repository procedures so every project and every AI agent CLI runs them the same way.

[한국어](README.ko.md)

[Quick Start](#quick-start) · [Skills](#skills) · [Docs](#documentation) · [Updating](#updating) · [License](#license)

## What This Is

Using AI agents (Claude Code, Codex, Antigravity CLI) across side projects means re-explaining branch rules, commit rules, and release procedures to every project and every agent. jig removes that repetition: it installs the same set of procedure skills into any agent environment, and manages updates and health checks after the install.

Supported: **Claude Code** (recommended), **Codex**, **Antigravity CLI**

## Quick Start

![jig quick start: install into one CLI, run project-setup for profile, rubric, branch convergence and a check, verify with jig-doctor, then work through develop-task-flow and github-release](docs/assets/quick-start.svg)

You need a git repository, plus `curl` or `wget` for Codex and Antigravity. A `gh` login is required to converge GitHub settings, but not to install the skills.

### 1. Install — pick the one CLI you use

**Claude Code** (recommended) — run inside a session. The plugin host manages install, update, and removal, and the `PreToolUse` guard hook that inspects push commands before they run ships only here.

```text
/plugin marketplace add 0x0w1/jig
/plugin install jig@jig
```

**Codex** and **Antigravity CLI** — run from the repository root.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/jig/main/install.sh \
  | sh -s -- --target codex --scope project        # or --target antigravity
```

Options, install layout, skill namespacing, and removal: [installation guide](docs/installation.md).

### 2. Bind the repository

Run `project-setup` in an agent session: `/jig:project-setup` on Claude Code, `jig-project-setup` on Codex and Antigravity.

One run settles four things.

1. Selects and verifies the GitHub profile this repository uses (the globally active account is left alone)
2. Settles the version grading rubric and records it in `.jig/versioning.md`
3. Converges the `main` and `develop` branches through `github-sync`, and asks before setting up branch protection — optional, since GitHub allows it on public repositories and on private ones only with a paid plan
4. Checks the installation with `jig-doctor`

### 3. Verify

Run `/jig:jig-doctor` (`jig-doctor` on Codex and Antigravity) for a read-only report on the installed version, file drift, branch protection, the GitHub profile, and the rubric file. Anything that needs fixing is reported along with the skill that fixes it.

From there, call a skill by name or just say what you want; the agent picks it.

## Skills

Unlike a plain collection of skills, jig converges *repository state* — the branch model, branch protection, release discipline — and not only session procedures, then manages the install afterwards with `jig-update` and `jig-doctor`. One procedure source (`skills/`) is rendered into each CLI's native format: a plugin for Claude Code, `jig-` prefixed files for Codex and Antigravity.

| Skill | Role |
|---|---|
| `develop-task-flow` | Branch, work, squash merge into `develop` |
| `github-release` | Fast-forward `develop` to `main`, tag, publish notes |
| `github-sync` | Branches, optional protection, local `pre-push` guard |
| `project-setup` | Bind the repository to a GitHub CLI profile |
| `jig-update` | Update an installation to the latest release |
| `jig-doctor` | Read-only health check of the installation |
| `readme` | Draft a README, or fix its drift against the code |
| `version-rubric` | Settle `patch`/`minor`/`major` in `.jig/versioning.md` |
| `rubric-scan` | Classify the project type, recommend a rubric |

There is a **single merge flow, solo-cli**: a work branch is squash-merged into `develop` locally and pushed directly. No pull requests.

Skill bodies and the rubric catalog are written in English. What a skill **produces** — reports, commit bodies, release notes, a README — follows the language that repository already uses.

## Documentation

Written in Korean, except the rubric catalog.

- [Installation guide](docs/installation.md): what lands where for each CLI, installer options, skill namespacing, and removal.
- [Version rubric](docs/version-rubric.md): how an installed project grades `patch`/`minor`/`major` on its own terms, plus the `.jig/versioning.md` file contract.
- [Rubric catalog by project type](skills/version-rubric/rubrics/INDEX.md): 17 rubric drafts and the detection signal table `rubric-scan` uses. In English.
- [Versioning policy](docs/versioning.md): commentary on how jig itself grades releases. The normative source is `.jig/versioning.md`.
- [GitHub repository settings](docs/github-repository-settings.md): what the installer applies, and how optional branch protection is decided.
- [Roadmap](docs/roadmap.md): jig's identity and its trigger-conditional direction candidates.

## Updating

Run the `jig-update` skill. It inventories jig across Claude Code, Codex, and Antigravity in the current project and user scopes, then updates every detected installation together regardless of which agent invoked it. Claude Code inventory includes both plugin scopes and existing standalone copies under `.claude/skills` or `~/.claude/skills`. It preserves each target's selected skill set, summarizes the releases in between, and converges repository settings with `github-sync`.

```text
/jig:jig-update
```

To do it by hand instead, use what each CLI provides. On Claude Code the plugin host owns the update:

```text
/plugin marketplace update jig
/reload-plugins
```

On Codex and Antigravity, run the install command again. The installer is idempotent and backs up changed files as `.bak`.

Existing Claude Code standalone jig skills are updated only through `jig-update`: it verifies jig provenance before touching `.claude/skills`, preserves the directories already installed, and backs up changed files as `.bak`.

## License

This project is licensed under the terms of the MIT license.
