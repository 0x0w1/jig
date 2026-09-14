# Installation Guide

[한국어](../ko/installation.md)

jig **installs differently on each supported CLI.** There is no way to install everything at once; pick the CLI you use.

| CLI | How it installs | Unit | Owner |
|---|---|---|---|
| Claude Code | plugin marketplace | the `jig` plugin | the Claude Code host |
| Codex | plugin marketplace | the `jig` plugin | the Codex host |
| Antigravity CLI | `install.sh` | `.agents/skills/jig-*` files | the jig installer |

For just the commands, see [Quick Start in the README](../../README.md#quick-start). This document explains **what each path installs, where, and how it is managed afterwards.**

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
/jig:jig-setup
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

`jig-doctor` uses the same installation inventory contract as `jig-update`. It inspects both standalone roots without writing, distinguishes verified, legacy-unledgered, invalid-ledger, partial, provenance-conflict, and non-owned states, and reports them alongside every detected Claude Code plugin, Codex, and Antigravity scope.

### Removing it

Before removing the plugin, ask `/jig:github-sync` to uninstall the current repository's local pre-push guard. The plugin host removes plugin files but cannot clean clone-local `.git/hooks` files automatically.

```text
/plugin uninstall jig@jig    # remove entirely
/plugin disable jig@jig      # only disable
```

---

## Codex

### What gets installed

Codex has a plugin system, so jig installs there as the same plugin Claude Code uses, from the same marketplace repository. The installer is not involved.

```bash
codex plugin marketplace add 0x0w1/jig
codex plugin add jig@jig
```

The plugin is cached under `${CODEX_HOME:-~/.codex}/plugins/`, and the install is recorded in `${CODEX_HOME:-~/.codex}/config.toml`:

```toml
[marketplaces.jig]
source_type = "git"
source = "https://github.com/0x0w1/jig.git"

[plugins."jig@jig"]
enabled = true
```

Nothing is written into your repository. The install is user-global, so every repository on the machine sees the skills.

### Using it

Bundled skills are namespaced by the plugin, so they load as `jig:github-sync`, `jig:jig-doctor`, and so on — the same names Claude Code shows, without the leading slash. `codex plugin list` shows what is installed.

### The push guard

Codex does not run a plugin's own hooks, so the `PreToolUse` push guard is not carried by the plugin. `jig:github-sync` installs it as a repository hook entry in `.codex/hooks.json` instead, pointing at a clone-local copy of the guard. Codex runs a non-managed hook only after you review and trust it once in `/hooks`.

### Versions

The plugin is host-managed and carries no jig version stamp. Refresh it with:

```bash
codex plugin marketplace upgrade jig
codex plugin add jig@jig
```

`jig-update` runs those two commands for you and reports Codex as pending if the CLI is unavailable.

### Removing it

Before removing the plugin, ask `jig:github-sync` to uninstall the current repository's local guards: the native hook entry in `.codex/hooks.json`, then the pre-push hook. The cleanup removes only jig's own entry and jig-marked hook, keeps every user entry, and restores a user hook that jig backed up.

```bash
codex plugin remove jig@jig
codex plugin marketplace remove jig
```

### Migrating from the file installation

Before v0.22.0 the installer copied `jig-` prefixed skill files into `.agents/skills` and wrote a managed block into `AGENTS.md`. That installation still loads, but the installer no longer targets Codex and will not refresh it. To migrate, install the plugin with the two commands above, then remove the block between `<!-- jig:start ... -->` and `<!-- jig:end ... -->` in `AGENTS.md`. **Remove `.agents/skills/jig-*` only if Antigravity is not also installed in that repository** — both CLIs read the same directory.

---

## Antigravity CLI

### What gets installed

Antigravity has no plugin system, so the installer copies files.

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

**It shares the project scope path (`.agents/skills`) with a legacy Codex file installation.** That is safe because the skill files are identical; only the rules files differ, as `GEMINI.md` and `AGENTS.md`. It is also why migrating Codex to the plugin must not delete `.agents/skills/jig-*` while Antigravity is still installed.

### Versions and removal

The installed version and skill selection are stamped inside the managed block in `GEMINI.md`, and `jig-update` reads that stamp to reinstall the same selection at the latest release. To remove it, run the guard cleanup from `jig-github-sync`, delete `.agents/skills/jig-*`, then delete only the span between the jig markers in `GEMINI.md`.

---

## Installer Behavior

Applies to Antigravity installs only. Claude Code and Codex install the `jig` plugin from their own marketplaces.

### Installer options

| Option | Description |
|---|---|
| `--target antigravity` | The CLI to install (required). `antigravity` is the only value; `codex` and `claude-code` use plugins |
| `--scope project\|global` | Install scope; defaults to `project` |
| `--github-profile <profile>` | Profile to use when the install should also wire up GitHub (optional). `--github-account` also works |
| `--github-host <host>` | GitHub Enterprise host |
| `--version vX.Y.Z` | Install or roll back to a specific jig release |
| `--skills a,b,c` | Install only the selected skills from the manifest |
| `--configure-git-user` | Set the local `user.name` and `user.email` |
| `--dry-run` | Print the planned work without changing files |
| `--force` | Replace an existing managed file that carries no jig marker |

The installer is for Antigravity only. The Claude Code and Codex plugin hosts own install, update, and removal there, so neither uses `install.sh`.

A normal install does not prompt to change the local git user. Terminal input may still be needed when a `gh` login is required or `--configure-git-user` is used.

### Reserved names

jig claims only the `jig` plugin name and skill names starting with `jig-`. Keep that prefix off your own skills and nothing collides. On Claude Code the host namespaces plugin skills, so even identical names leave both in place.

### Idempotency

The installer checks the current state before writing. When a file is already where it should be, it logs `PASS` and skips it. A file that must change is backed up as `.bak` first.

`--dry-run` shows the planned work without changing anything.

### The managed block

jig owns only the span between the markers in `GEMINI.md` (and in `AGENTS.md` for a legacy Codex file installation).

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

Without a profile, the skill files still install and only this step is deferred until `jig-setup`. It is also skipped, with a pass log, when there is no `.git` repository or the repository is not connected to GitHub.

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
sh install.sh --target antigravity --scope project --configure-git-user
```

The values can also be passed non-interactively.

```bash
sh install.sh --target antigravity --scope project \
  --git-user-name "Your Name" --git-user-email "your@email.com"
```

---

## First Step After Installing

Whichever CLI you installed, the GitHub profile can be settled afterwards. Run the `jig-setup` skill to verify the installation and the profile, and to converge the repository onto the jig branch model.

- Claude Code: `/jig:jig-setup`
- Codex: `jig:jig-setup`
- Antigravity: `jig-setup`

The skill stores no token; it uses only the profile name from `JIG_GITHUB_PROFILE` or the local `git config`. It then runs `github-sync` to ensure `develop` and settle branch protection, and `jig-doctor` to check the state.
