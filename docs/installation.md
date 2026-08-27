# Installation Guide

[한국어](installation.ko.md)

jig **installs differently on each supported CLI.** There is no way to install everything at once; pick the CLI you use.

| CLI | How it installs | Unit | Owner |
|---|---|---|---|
| Claude Code | plugin marketplace | the `jig` plugin | the Claude Code host |
| Codex | `install.sh` | `.agents/skills/jig-*` files | the jig installer |
| Antigravity CLI | `install.sh` | `.agents/skills/jig-*` files | the jig installer |

For just the commands, see [Quick Start in the README](../README.md#quick-start). This document explains **what each path installs, where, and how it is managed afterwards.**

Installation is performed one target at a time, but updates are coordinated. One `jig-update` run inventories Claude Code, Codex, and Antigravity across the current project's `project`/`local` scopes and the user's global scope, then updates every detected instance. Invoking it from one agent does not restrict the update to that agent, and it never installs a target or scope that was not already present.

---

## Claude Code

### What gets installed

The plugin copies no skill file into your repository. Once the marketplace is registered and the plugin installed, Claude Code downloads it into its own plugin directory and loads it from there.

In project scope, one settings file is all that stays in the repository.

```text
.claude/
  settings.json    # extraKnownMarketplaces + enabledPlugins
```

Commit that file and collaborators get the same plugin when they open the repository. In user scope it is recorded in `~/.claude/settings.json` and nothing lands in the repository.

`CLAUDE.md` is **left alone.** The host exposes plugin skills directly through the frontmatter `description`, so there is no reason to list the skills again in a rules file.

### Using it

The host namespaces the skills.

```text
/jig:github-sync
/jig:develop-task-flow
/jig:github-release
/jig:project-setup
/jig:jig-update
/jig:jig-doctor
/jig:readme
/jig:version-rubric
/jig:rubric-scan
```

A custom skill of your own with the same name (`/github-release`) **survives alongside it**, because the namespaces differ.

### Versions

The host manages the version. No version stamp is left in the repository.

```text
/plugin marketplace update jig          # move to the latest
/reload-plugins                          # apply it to the current session
```

To pin a specific release, re-add the marketplace at a tag ref.

```text
/plugin marketplace add https://github.com/your-account/jig.git#v0.2.0
```

### Existing standalone skills

The marketplace plugin remains the supported installation path. `jig-update` also recognizes earlier or manually copied standalone jig skill sets that already exist under `./.claude/skills` or `~/.claude/skills`; it does not create a new standalone installation.

The first successful compatibility update writes a root `.jig-installation` ledger with the release version, target, scope, and exact skill-to-directory selection, plus a `.jig-provenance` marker inside every owned skill directory. Before that first ledger exists, a legacy directory is accepted only when both its frontmatter name and the canonical payload title match; a name match by itself is left untouched. Later updates require the ledger and markers to agree.

Each standalone root updates as one transaction. `jig-update` downloads all selected payload files before changing the installation, keeps `.bak` copies of changed files, and restores the prior files, backups, markers, and ledger if applying any file fails.

Before downloading those files, the updater validates every selected `dist/files.tsv` entry as a strict relative file path. Absolute paths, empty or traversal components, reserved marker and backup names, unsupported characters, and any existing symlink component are rejected. A rejected catalog leaves that standalone root unchanged, including its backups, provenance markers, and ledger.

Because those roots may also contain personal skills, their existence alone proves nothing. The updater requires the installed `jig-update/SKILL.md` to carry jig's name, title, and `0x0w1/jig` repository identity before it changes anything. It then refreshes only the jig skill directories already present, preserves unprefixed or `jig-` prefixed names, adds supporting files only inside those selected directories, and backs up every changed file as `.bak`. Unrecognized roots are left untouched.

### Removing it

```text
/plugin uninstall jig@jig    # remove entirely
/plugin disable jig@jig      # only disable
```

---

## Codex

### What gets installed

Codex has no plugin system, so the installer copies files.

project scope:

```text
./AGENTS.md                       # jig managed block added or replaced
.agents/skills/
  jig-github-sync/SKILL.md
  jig-github-release/SKILL.md
  jig-develop-task-flow/SKILL.md
  jig-project-setup/SKILL.md
  jig-update/SKILL.md
  jig-doctor/SKILL.md
  jig-readme/SKILL.md
  jig-version-rubric/SKILL.md
  jig-version-rubric/rubrics/      # the per-type rubric catalog
  jig-rubric-scan/SKILL.md
```

A skill is a directory, not a single file. A skill that ships reference files alongside it, such as `jig-version-rubric`, installs those too; the installer downloads whatever the release's `dist/files.tsv` lists.

global scope:

```text
~/.codex/AGENTS.md
~/.agents/skills/jig-*/
```

### Using it

Codex recognizes the `SKILL.md` under `.agents/skills/*` as a native skill. Both the directory name and the frontmatter `name` carry the `jig-` prefix, so they never collide with skills you wrote. The managed block in `AGENTS.md` holds only the list of installed skills; the procedures themselves load from each `SKILL.md`.

### Versions

The installed version and skill selection are stamped inside the managed block.

```text
<!-- jig:version v0.2.0 skills=github-sync,github-release,develop-task-flow,project-setup,jig-update,jig-doctor -->
```

The `jig-update` skill reads that stamp to reinstall the same selection at the latest release, and `jig-doctor` uses it as the basis for diagnosis. To update, run the same command again — the installer is idempotent and refreshes only what changed.

### Removing it

The installer deletes nothing. Remove it yourself.

```bash
rm -rf .agents/skills/jig-github-sync .agents/skills/jig-github-release \
  .agents/skills/jig-develop-task-flow .agents/skills/jig-update .agents/skills/jig-doctor \
  .agents/skills/jig-project-setup .agents/skills/jig-readme \
  .agents/skills/jig-version-rubric .agents/skills/jig-rubric-scan
```

In `AGENTS.md`, delete only the span between `<!-- jig:start ... -->` and `<!-- jig:end ... -->`. jig never touched anything outside the block.

---

## Antigravity CLI

### What gets installed

The same file-copy approach as Codex; only the rules file name and the global scope paths differ.

project scope:

```text
./GEMINI.md                       # jig managed block added or replaced
.agents/skills/jig-*/
```

global scope:

```text
~/.gemini/GEMINI.md
~/.gemini/config/skills/jig-*/
```

### Using it

Antigravity CLI reads `GEMINI.md` at the workspace root as its rules file and recognizes native skills under `.agents/skills/*`.

**It shares the project scope path (`.agents/skills`) with Codex.** Installing both CLIs in one repository is safe because the skill files are identical; only the rules files differ, as `AGENTS.md` and `GEMINI.md`.

### Versions and removal

Same as Codex. The stamp goes into the managed block in `GEMINI.md`.

---

## Installer Behavior

Applies to Codex and Antigravity installs only.

### Installer options

| Option | Description |
|---|---|
| `--target codex\|antigravity` | The one CLI to install (required). There is no `all`, and `claude-code` is not a target |
| `--scope project\|global` | Install scope; defaults to `project` |
| `--github-profile <profile>` | Profile to use when the install should also wire up GitHub (optional). `--github-account` also works |
| `--github-host <host>` | GitHub Enterprise host |
| `--version vX.Y.Z` | Install or roll back to a specific jig release |
| `--skills a,b,c` | Install only the selected skills from the manifest |
| `--configure-git-user` | Set the local `user.name` and `user.email` |
| `--dry-run` | Print the planned work without changing files |
| `--force` | Replace an existing managed file that carries no jig marker |

The installer is for Codex and Antigravity only. Claude Code's plugin host owns install, update, and removal, so it never uses `install.sh`.

A normal install does not prompt to change the local git user. Terminal input may still be needed when a `gh` login is required or `--configure-git-user` is used.

### Reserved names

jig claims only the `jig` plugin name and skill names starting with `jig-`. Keep that prefix off your own skills and nothing collides. On Claude Code the host namespaces plugin skills, so even identical names leave both in place.

### Idempotency

The installer checks the current state before writing. When a file is already where it should be, it logs `PASS` and skips it. A file that must change is backed up as `.bak` first.

`--dry-run` shows the planned work without changing anything.

### The managed block

jig owns only the span between the markers in `AGENTS.md` and `GEMINI.md`.

- With markers present, only that span is replaced.
- Without markers, existing content is **preserved** and the block is appended at the end of the file.
- Use `--force` to replace the whole file with the jig template.

### Selective install

`--skills a,b` installs a subset. Omit it and every default skill in `manifest.tsv` is installed; with a selection, the skills left out also disappear from the managed block list.

### Version resolution

The default is the latest GitHub release tag. If the lookup fails, it falls back to the `main` branch.

- `--version vX.Y.Z` or `JIG_VERSION`: pin to or roll back to a specific release
- `REPO_RAW_URL`: skip version resolution and use that URL as-is

### GitHub settings sync

In project scope, when a GitHub profile is already settled and `gh` is usable, the installer also does the following.

1. Settles the profile from `JIG_GITHUB_PROFILE`, the local `jig.githubProfile`, or `--github-profile`, running `gh auth login` if needed. It uses that profile's credential per command and never changes the globally active account.
2. Creates `develop` from the current commit of `main` when the remote has no `develop`.

Without a profile, the skill files still install and only this step is deferred until `project-setup`. It is also skipped, with a pass log, when there is no `.git` repository or the repository is not connected to GitHub.

**The installer never applies branch protection.** It points at the remaining step in the `GUIDE` output, and the `github-sync` skill applies it — asking first, since it is optional. See [GitHub repository settings](github-repository-settings.md) for the conditions.

### Per-repository GitHub profile

Persistent settings store only the login name and host in the repository's `.git/config`. The OAuth token stays in the `gh` credential store.

```bash
git config --local jig.githubProfile your-account
git config --local jig.githubHost github.com
```

For a one-off or per-session override, set it in the environment that starts the agent.

```bash
JIG_GITHUB_PROFILE=your-account JIG_GITHUB_HOST=github.com <agent-command>
```

The environment variables win over the local config. Either way, jig skills never run `gh auth switch`.

### Local git author

A normal install does not ask. Turn it on with an option when you want it.

```bash
sh install.sh --target codex --scope project --configure-git-user
```

The values can also be passed non-interactively.

```bash
sh install.sh --target codex --scope project \
  --git-user-name "Your Name" --git-user-email "your@email.com"
```

---

## First Step After Installing

Whichever CLI you installed, the GitHub profile can be settled afterwards. Run the `project-setup` skill to verify the installation and the profile, and to converge the repository onto the jig branch model.

- Claude Code: `/jig:project-setup`
- Codex and Antigravity: `jig-project-setup`

The skill stores no token; it uses only the profile name from `JIG_GITHUB_PROFILE` or the local `git config`. It then runs `github-sync` to ensure `develop` and settle branch protection, and `jig-doctor` to check the state.
