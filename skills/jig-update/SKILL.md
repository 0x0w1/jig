---
name: jig-update
description: Use when updating the jig installation in this repository to the latest jig release by updating the Claude Code plugin through the marketplace, comparing the installed jig:version stamp for codex and antigravity with the latest GitHub release, summarizing the changes, re-running the installer per target, and converging repository settings with github-sync.
---

# jig Update

Use this repository skill to update the installed jig procedures to the latest release.

## Update Model

Each CLI updates on its own path; there is no combined update.

- **Claude Code** installs jig as the `jig` plugin. The host updates it: marketplace auto-update, or `/plugin marketplace update jig`. Skills are namespaced as `/jig:<skill>` and never touch `.claude/skills`. There is no version stamp to read or write for this target.
- **Codex and Antigravity** have no plugin system. Their `jig-` prefixed skill directories under `.agents/skills` are refreshed by re-running `install.sh` once per target, pinned to the latest tag. The installer is idempotent: unchanged files pass, changed files are backed up as `*.bak`, and managed blocks are replaced in place.
- A skill is a directory, not always one `SKILL.md`. The installer reads `dist/files.tsv` from the pinned version and installs every file that skill ships, such as the rubric catalog under `jig-version-rubric/rubrics`. Files an older version installed and the new payload no longer lists stay on disk; report them and remove them only with explicit confirmation.
- For codex and antigravity, the installed version and skill selection are stamped inside the jig managed block as `<!-- jig:version vX.Y.Z skills=<a,b,c> -->` in `AGENTS.md` or `GEMINI.md`. A stamp without `skills=` means the full default skill set.
- The latest version is the latest GitHub release tag of `0x0w1/jig`.
- Repository-side convergence (branch protection, legacy file and label cleanup) is handled by the `github-sync` skill after the update, and is idempotent across skipped versions.
- `.jig/` is owned by the project, not by the installer. The version rubric at `.jig/versioning.md` is never written, replaced, or removed by an update; `version-rubric` owns it.

## GitHub Profile

Before any `gh` command, resolve the host from `JIG_GITHUB_HOST`, local `jig.githubHost`, then `github.com`, and resolve the profile from `JIG_GITHUB_PROFILE`, then local `jig.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Migration Blocks

Release notes carry migration work as marker blocks, not prose. Collect them from every release in the range and merge them in release order.

```md
<!-- jig:start migration-auto -->
- `rm -f .github/workflows/drafter.yaml`
<!-- jig:end migration-auto -->

<!-- jig:start migration-manual -->
- Decide whether `develop` keeps its required status checks.
<!-- jig:end migration-manual -->
```

- **`migration-auto`**: execute unattended. Items are idempotent, so an already-absent target counts as done, and replaying a skipped version is safe. Report each item as applied, already satisfied, or failed.
- **`migration-manual`**: never execute without approval. Present every item, ask, and apply only what the user approves. Leave the rest listed as pending in the report.
- **A marker counts only when it is the entire line**, matching `^<!-- jig:(start|end) migration-(auto|manual) -->$`. Release notes routinely name these markers in prose, so a mention inside backticks or mid-sentence is text, not a block boundary. Never execute an item because a marker name appeared in a sentence.
- An opened block with no matching end marker is malformed: report it and execute nothing from it.
- Text outside these blocks is context for the user, not instructions to run.
- A release with a `migration-manual` block is graded `major`; treat it as a signal to slow down and confirm before touching repository state.

## Migrating a Pre-Rename Installation

An installation made before the rename from `spai` to `jig` is updated in place, not reinstalled from scratch.

1. Detect it: `.agents/skills/spai-*` directories, a `<!-- spai:version ... -->` stamp, or `spai@spai` in the Claude Code plugin list.
2. **Codex and Antigravity** — run the installer normally. It writes the `jig-*` skill directories and replaces the legacy `<!-- spai:start ... -->` managed block in place, so no second block appears. Then report the leftover `.agents/skills/spai-*` directories and delete them **only with explicit confirmation**; they are files on the user's disk.
3. **Claude Code** — the host owns plugin identity, so this part is manual. Tell the user to run `/plugin marketplace add 0x0w1/jig`, `/plugin install jig@jig`, `/plugin uninstall spai@spai`, then `/reload-plugins`. Do not attempt it for them.
4. **Local config** — when only `spai.githubProfile`, `spai.versionRubric`, or `spai.branchProtection` exist, copy each to its `jig.` name with `git config --local` and report both. Remove the old keys only with confirmation.
5. **`.spai/versioning.md`** — project-owned. Report it, offer to move it to `.jig/versioning.md`, and move it only when the user says so. Every skill reads the legacy path meanwhile.
6. **Push guard** — `github-sync` replaces a `# spai:pre-push v<N>` hook with the `jig` version when the user reruns it. Report it; do not edit hooks from this skill.

Nothing here runs unattended except step 2's installer pass. Deleting the user's old directories and keys always needs a yes.

## Safety Rules

- Do not force push.
- Do not run the installer with `--force` unless the user explicitly asks for a full template replacement.
- Do not delete branches, labels, or files without explicit confirmation; leave `*.bak` backups in place.
- Do not create releases or tags.
- Do not uninstall the plugin as part of an update.
- Do not run a `migration-manual` item without explicit approval for that item, and do not run anything that is not inside a migration block.
- Stop and report if the installer fails, the version stamp does not update, or a `migration-auto` item fails.
- Preserve unrelated user changes.

## Procedure

1. Read the installed version stamp for codex and antigravity:
   - `grep -h "jig:version" AGENTS.md GEMINI.md 2>/dev/null | head -n 1`
   - A missing stamp means either a Claude Code only install or an install without a version stamp; continue and treat the installed version as unknown.
2. Determine the latest release:
   - `gh api repos/0x0w1/jig/releases/latest --jq .tag_name`
   - Fallback without `gh`: `curl -fsSL https://api.github.com/repos/0x0w1/jig/releases/latest` and read `tag_name`.
3. If the installed stamp equals the latest tag and the plugin is current, report up to date and stop.
4. Collect the release notes between the installed version and the latest:
   - `gh release list --repo 0x0w1/jig --limit 20`
   - `gh release view <tag> --repo 0x0w1/jig` for each release newer than the installed version.
   - Extract the `migration-auto` and `migration-manual` blocks from each and merge them in release order.
5. Report the version delta with a short summary of the changes in the repository's own language, defaulting to English, the count of auto and manual migration items, and the full text of every manual item. Ask for approval before applying, unless the user already asked for the update to be executed end to end. Approval to update never implies approval for manual migration items; ask for those separately.
6. Detect the installed targets:
   - `jig@jig` in `claude plugin list` or in `.claude/settings.json` → claude-code (plugin)
   - `./AGENTS.md` with jig markers → codex
   - `./GEMINI.md` with jig markers → antigravity
7. Update Claude Code, when the plugin is installed:
   - `/plugin marketplace update jig`
   - Confirm `claude plugin list` still shows `jig@jig` as enabled.
   - To pin a specific release instead of tracking the default branch, re-add the marketplace at that tag: `/plugin marketplace add https://github.com/0x0w1/jig.git#<latest>`.
   - Tell the user to run `/reload-plugins` in their Claude Code session for the new version to take effect.
8. Update codex and antigravity, when those targets are installed. Run the installer once per target; a GitHub profile is optional for the file update:
   - `curl -fsSL https://raw.githubusercontent.com/0x0w1/jig/main/install.sh | sh -s -- --target <target> --scope project --version <latest> --skills <stamped skills>`
   - When a profile is configured, the installer resolves it from the environment or local git config and also converges GitHub settings. Otherwise it updates the files and defers GitHub convergence to `project-setup`.
   - When the stamp has no `skills=`, omit `--skills` so the installer applies the defaults.
9. Verify the `AGENTS.md` or `GEMINI.md` stamp now shows the latest version, and that every path in the new `dist/files.tsv` exists under the installed skill directories. Claude Code has no stamp to verify.
10. Apply the merged `migration-auto` items in release order, after the payload is updated so the steps run against the new version. Each item is idempotent: record it as applied, already satisfied, or failed, and continue past already-satisfied items. Stop and report on the first failure rather than improvising a fix.
11. Present the merged `migration-manual` items and apply only the ones the user approves. Anything not approved stays pending and is named in the report.
12. When a GitHub profile is configured, run the `github-sync` skill to converge branch protection and report legacy files or labels; delete them only with explicit confirmation. Otherwise recommend `project-setup` and leave GitHub convergence pending.
13. Run the `jig-doctor` skill to confirm the updated installation is healthy; include its findings in the report.
14. Report.

## Final Report

Keep reports short and include:

- Installed version before and after, per target
- Releases applied and their key changes
- Claude Code plugin state and whether `/reload-plugins` is still pending
- `migration-auto` items applied, already satisfied, or failed
- `migration-manual` items approved and applied, versus still pending
- Files updated or backed up
- Commands that could not run and why
- User next actions, if any
