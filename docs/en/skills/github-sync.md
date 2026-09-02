# GitHub Sync

<!-- jig:skill-source-digest e0f6735d916529e9259a0248c183a3b60e858012 -->

[한국어](../../ko/skills/github-sync.md) · [Skill index](index.md) · [Repository settings](../github-repository-settings.md)

## Overview

`github-sync` converges a repository on jig's CLI release model: `main` and `develop`, optional server-side protection, and two layers of local guard — the git `pre-push` hook, and a `PreToolUse` push hook installed natively for Codex and Antigravity (Claude Code ships the same hook inside the plugin). It is idempotent and deliberately excludes releases, tags, pull-request templates, labels, and Release Drafter automation.

## When to use

Use it during `jig-setup`, after `jig-update`, when `develop` is missing, when protection or the local guard drifted, or when a clone has not recorded its protection choice. Use `github-release` to publish; sync never creates a release.

## Invocation and prerequisites

- Claude Code: `/jig:github-sync`
- Codex and Antigravity: `jig-github-sync`
- Requires a Git repository. GitHub operations additionally require `gh`, repository access, and the profile selected by `JIG_GITHUB_PROFILE` or local `jig.githubProfile`.

## Workflow

```mermaid
flowchart TD
    Inspect[Inspect worktree, remotes, gh access] --> Main{main exists?}
    Main -- No --> Stop[Report the missing prerequisite]
    Main -- Yes --> Develop{develop exists?}
    Develop -- No --> Create[Create develop from main and push]
    Develop -- Yes --> Probe
    Create --> Probe[Probe admin, visibility, and protection API]
    Probe --> Available{Protection available and permitted?}
    Available -- No --> Guard[Run managed pre-push installer]
    Available -- Yes --> Choice{Recorded choice?}
    Choice -- enabled --> Apply[Apply policy convergently]
    Choice -- skipped --> Guard
    Choice -- none --> Ask[Ask once]
    Ask -- Yes --> Apply
    Ask -- No --> Record[Record skipped locally]
    Apply --> Guard
    Record --> Guard
    Guard --> Hosts{Codex or Antigravity stamp?}
    Hosts -- Yes --> Native[Add or refresh the native hook entry]
    Hosts -- No --> Legacy
    Native --> Legacy[Report legacy release files]
```

Protection blocks force pushes and deletion on both branches while allowing direct pushes and requiring neither PR reviews nor status checks. A private repository on a plan without protection normally returns `403`; that is informational, not a defect.

## Reads and writes

The skill reads Git branch/remotes, GitHub repository permissions and protection, `jig.githubProfile`, `jig.githubHost`, and `jig.branchProtection`. It may create and push `develop`, update protection after confirmation, record the local choice, and manage `.git/hooks/pre-push` through its shipped `assets/pre-push` source and `scripts/manage-pre-push.sh` helper.

The local guard blocks deletion and non-fast-forward pushes to `main`/`develop`, and allows `main` updates only from `develop:main`. It is local defense; server-side protection remains authoritative.

The helper installs atomically, repairs a jig-owned drifted copy, and refuses a configured `core.hooksPath`. It never replaces an unmarked user hook without explicit confirmation. If replacement is approved, it preserves that hook as `.git/hooks/pre-push.jig-user-backup`.

The second layer is `scripts/manage-native-hooks.sh`. For each host whose rules file carries the jig stamp it adds one hook entry — `.codex/hooks.json` for Codex, `.agents/hooks.json` for Antigravity — that runs the shipped `assets/guard-push.sh` before any shell command; a push that the git hook would refuse, or that carries `--no-verify`, is refused before it runs. The entry holds only the guard's repository-relative path, so `jig-update` refreshes the guard without changing the entry. Other entries in either file are preserved; merging needs `jq`, and without it the manager writes only a fresh file. Codex runs a hook only after the user reviews it once in `/hooks`; the report says so every time. Project scope only.

## Decision points and safety

- Ask once before enabling available protection unless the checkout already records `enabled` or `skipped`.
- Never overwrite an unmarked user-authored `pre-push` hook without explicit confirmation and a `.jig-user-backup` copy.
- Never rewrite a user's entry in `.codex/hooks.json` or `.agents/hooks.json`; only the jig-marked entry is added, updated, or removed, and an unparseable file or a symlink is refused.
- Never grant Codex hook trust for the user; report the `/hooks` step instead.
- Never force push, delete branches, create tags/releases, configure `core.hooksPath`, rename the default branch, or silently remove legacy files.
- When protection is unavailable or skipped, report that the local guards are the only barrier on this machine.

## Uninstall cleanup

Run both helpers' `uninstall` modes before removing the skill or plugin from the current project — the native hook manager first, while the guard payload still exists. The native manager removes only its own entry and deletes the file (and an emptied `.codex/`) only when nothing else was in it; the pre-push manager removes only a hook with the jig ownership marker and restores the confirmed user-hook backup when present. Removing a user/global installation cannot discover every clone, so each project checkout must be cleaned explicitly.

## Outputs

The report lists branch creation/current state, protection as applied/skipped/unavailable/not permitted, local pre-push guard state, the native hook state per detected host (with the Codex `/hooks` trust reminder), legacy files found, blocked commands, and next actions.

## Related skills

- [`jig-setup`](jig-setup.md) selects the GitHub profile before sync.
- [`jig-update`](jig-update.md) delegates repository convergence here after payload updates.
- [`jig-doctor`](jig-doctor.md) diagnoses protection and guard drift without fixing it.
- [`github-release`](github-release.md) consumes the converged branch model.

## Source

- [`skills/github-sync/SKILL.md`](../../../skills/github-sync/SKILL.md)
- [`guard-push.sh`](../../../skills/github-sync/assets/guard-push.sh), the one guard source for every host
- [GitHub repository settings](../github-repository-settings.md)
