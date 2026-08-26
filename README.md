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

- **`develop-task-flow`** — Work on a `feature/fix/chore` branch, then squash merge into `develop`
- **`github-release`** — Fast-forward `develop` to `main`, compute the version, tag and publish the release
- **`github-sync`** — Converge the `main` and `develop` branches; offer branch protection where the plan allows it; install the local `pre-push` guard
- **`project-setup`** — Select and verify the per-repository GitHub CLI profile after installing SPAI
- **`spai-update`** — Move an installation to the latest SPAI release
- **`spai-doctor`** — Diagnose the installation (version, drift, protection, legacy leftovers); read-only
- **`readme`** — Classify the project type and draft `README.md`; check an existing README against the code and fix the drift
- **`version-rubric`** — Settle how this project grades `patch`/`minor`/`major` in `.spai/versioning.md`. Ships the per-type rubric catalog
- **`rubric-scan`** — Scan the repository to classify its project type and recommend a rubric from the catalog; read-only

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

- **Claude Code**: `/plugin marketplace update spai`, then `/reload-plugins`.
- **Codex and Antigravity**: run the install command again. The installer is idempotent and backs up changed files as `.bak`.

In an agent session the installed `spai-update` skill does the whole path: compare against the latest release, summarize the notes in between, update each target, and converge with `github-sync`.

## Contributing

<details>
<summary>Rebuilding and validating the distribution</summary>

```bash
sh scripts/build-dist.sh      # regenerate dist/ from skills/
sh scripts/validate-dist.sh   # payload, markers, rubric catalog contract
```

`dist/` is generated from the skills under `skills/`. The Claude Code plugin payload is `dist/claude-code-plugin/spai`, and the marketplace definition is `.claude-plugin/marketplace.json`.

</details>

## License

MIT License
