# SPAI

**Scaffolded Procedures for AI Agents** — a harness setup tool that installs repository operating procedures into AI agent CLI environments.

[한국어](README.ko.md)

[Quick Start](#quick-start) · [Skills](#skills) · [Docs](#documentation) · [Updating](#updating) · [License](#license)

## What This Is

Using AI agents (Claude Code, Codex, Antigravity CLI) across side projects means re-explaining branch rules, commit rules, and release procedures to every project and every agent. SPAI removes that repetition: it installs the same set of procedure skills into any agent environment, and manages updates and health checks after the install.

Supported: **Claude Code** (recommended), **Codex**, **Antigravity CLI**

## Quick Start

![SPAI quick start: install into one CLI, run project-setup for profile, rubric, branch convergence and a check, verify with spai-doctor, then work through develop-task-flow and github-release](docs/assets/quick-start.svg)

You need a git repository, plus `curl` or `wget` for Codex and Antigravity. A `gh` login is required to converge GitHub settings, but not to install the skills.

### 1. Install — pick the one CLI you use

**Claude Code** (recommended) — run inside a session. The plugin host manages install, update, and removal, and the `PreToolUse` guard hook that inspects push commands before they run ships only here.

```text
/plugin marketplace add 0x0w1/spai
/plugin install spai@spai
```

**Codex** and **Antigravity CLI** — run from the repository root.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target codex --scope project        # or --target antigravity
```

Options, install layout, skill namespacing, and removal: [installation guide](docs/installation.md).

### 2. Bind the repository

Run `project-setup` in an agent session: `/spai:project-setup` on Claude Code, `spai-project-setup` on Codex and Antigravity.

One run settles four things.

1. Selects and verifies the GitHub profile this repository uses (the globally active account is left alone)
2. Settles the version grading rubric and records it in `.spai/versioning.md`
3. Converges the `main` and `develop` branches through `github-sync`, and asks before setting up branch protection — optional, since GitHub allows it on public repositories and on private ones only with a paid plan
4. Checks the installation with `spai-doctor`

### 3. Verify

Run `/spai:spai-doctor` (`spai-doctor` on Codex and Antigravity) for a read-only report on the installed version, file drift, branch protection, the GitHub profile, and the rubric file. Anything that needs fixing is reported along with the skill that fixes it.

From there, call a skill by name or just say what you want; the agent picks it.

## Skills

Unlike a plain collection of skills, SPAI converges *repository state* — the branch model, branch protection, release discipline — and not only session procedures, then manages the install afterwards with `spai-update` and `spai-doctor`. One procedure source (`skills/`) is rendered into each CLI's native format: a plugin for Claude Code, `spai-` prefixed files for Codex and Antigravity.

| Skill | Role |
|---|---|
| `develop-task-flow` | Branch, work, squash merge into `develop` |
| `github-release` | Fast-forward `develop` to `main`, tag, publish notes |
| `github-sync` | Branches, optional protection, local `pre-push` guard |
| `project-setup` | Bind the repository to a GitHub CLI profile |
| `spai-update` | Update an installation to the latest release |
| `spai-doctor` | Read-only health check of the installation |
| `readme` | Draft a README, or fix its drift against the code |
| `version-rubric` | Settle `patch`/`minor`/`major` in `.spai/versioning.md` |
| `rubric-scan` | Classify the project type, recommend a rubric |

There is a **single merge flow, solo-cli**: a work branch is squash-merged into `develop` locally and pushed directly. No pull requests.

Skill bodies and the rubric catalog are written in English. What a skill **produces** — reports, commit bodies, release notes, a README — follows the language that repository already uses.

## Documentation

Written in Korean, except the rubric catalog.

- [Installation guide](docs/installation.md): what lands where for each CLI, installer options, skill namespacing, and removal.
- [Version rubric](docs/version-rubric.md): how an installed project grades `patch`/`minor`/`major` on its own terms, plus the `.spai/versioning.md` file contract.
- [Rubric catalog by project type](skills/version-rubric/rubrics/INDEX.md): 17 rubric drafts and the detection signal table `rubric-scan` uses. In English.
- [Versioning policy](docs/versioning.md): commentary on how SPAI itself grades releases. The normative source is `.spai/versioning.md`.
- [GitHub repository settings](docs/github-repository-settings.md): what the installer applies, and how optional branch protection is decided.
- [Roadmap](docs/roadmap.md): SPAI's identity and its trigger-conditional direction candidates.

## Updating

Run the `spai-update` skill. It compares the installation against the latest release, summarizes the notes in between, updates each target, and converges repository settings with `github-sync`.

```text
/spai:spai-update
```

To do it by hand instead, use what each CLI provides. On Claude Code the plugin host owns the update:

```text
/plugin marketplace update spai
/reload-plugins
```

On Codex and Antigravity, run the install command again. The installer is idempotent and backs up changed files as `.bak`.

## License

MIT License
