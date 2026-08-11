---
name: spai-update
description: Use when updating the SPAI installation in this repository to the latest SPAI release by updating the Claude Code plugin through the marketplace, comparing the installed spai:version stamp for codex and antigravity with the latest GitHub release, summarizing the changes, re-running the installer per target, and converging repository settings with github-sync.
---

# SPAI Update

Use this repository skill to update the installed SPAI procedures to the latest release.

## Update Model

Each CLI updates on its own path; there is no combined update.

- **Claude Code** installs SPAI as the `spai` plugin. The host updates it: marketplace auto-update, or `/plugin marketplace update spai`. Skills are namespaced as `/spai:<skill>` and never touch `.claude/skills`. There is no version stamp to read or write for this target.
- **Codex and Antigravity** have no plugin system. Their `spai-` prefixed skill directories under `.agents/skills` are refreshed by re-running `install.sh` once per target, pinned to the latest tag. The installer is idempotent: unchanged files pass, changed files are backed up as `*.bak`, and managed blocks are replaced in place.
- For codex and antigravity, the installed version and skill selection are stamped inside the SPAI managed block as `<!-- spai:version vX.Y.Z skills=<a,b,c> -->` in `AGENTS.md` or `GEMINI.md`. A stamp without `skills=` means the full default skill set.
- The latest version is the latest GitHub release tag of `0x0w1/spai`.
- Repository-side convergence (branch protection, legacy file and label cleanup) is handled by the `github-sync` skill after the update, and is idempotent across skipped versions.
- A `major` version jump means the release flow or repository policy changed; read the `### Migration` sections of the release notes before updating.

## Safety Rules

- Do not force push.
- Do not run the installer with `--force` unless the user explicitly asks for a full template replacement.
- Do not delete branches, labels, or files without explicit confirmation; leave `*.bak` backups in place.
- Do not create releases or tags.
- Do not uninstall the plugin as part of an update.
- Stop and report if the installer fails or the version stamp does not update.
- Preserve unrelated user changes.

## Procedure

1. Read the installed version stamp for codex and antigravity:
   - `grep -h "spai:version" AGENTS.md GEMINI.md 2>/dev/null | head -n 1`
   - A missing stamp means either a Claude Code only install or an install without a version stamp; continue and treat the installed version as unknown.
2. Determine the latest release:
   - `gh api repos/0x0w1/spai/releases/latest --jq .tag_name`
   - Fallback without `gh`: `curl -fsSL https://api.github.com/repos/0x0w1/spai/releases/latest` and read `tag_name`.
3. If the installed stamp equals the latest tag and the plugin is current, report up to date and stop.
4. Collect the release notes between the installed version and the latest:
   - `gh release list --repo 0x0w1/spai --limit 20`
   - `gh release view <tag> --repo 0x0w1/spai` for each release newer than the installed version.
   - Extract any `### Migration` sections.
5. Report the version delta with a short Korean summary of the changes and highlight migration steps. Ask for approval before applying, unless the user already asked for the update to be executed end to end.
6. Detect the installed targets:
   - `spai@spai` in `claude plugin list` or in `.claude/settings.json` → claude-code (plugin)
   - `./AGENTS.md` with SPAI markers → codex
   - `./GEMINI.md` with SPAI markers → antigravity
7. Update Claude Code, when the plugin is installed:
   - `/plugin marketplace update spai`
   - Confirm `claude plugin list` still shows `spai@spai` as enabled.
   - To pin a specific release instead of tracking the default branch, re-add the marketplace at that tag: `/plugin marketplace add https://github.com/0x0w1/spai.git#<latest>`.
   - Tell the user to run `/reload-plugins` in their Claude Code session for the new version to take effect.
8. Update codex and antigravity, when those targets are installed. Run the installer once per target. Determine the GitHub account first (`gh api user --jq .login`) or ask the user:
   - `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh | sh -s -- --target <target> --scope project --github-account <account> --version <latest> --skills <stamped skills>`
   - When the stamp has no `skills=`, omit `--skills` so the installer applies the defaults.
9. Verify the `AGENTS.md` or `GEMINI.md` stamp now shows the latest version. Claude Code has no stamp to verify.
10. Run the `github-sync` skill to converge branch protection and report legacy files or labels; delete them only with explicit confirmation.
11. Run the `spai-doctor` skill to confirm the updated installation is healthy; include its findings in the report.
12. Report.

## Final Report

Keep reports short and include:

- Installed version before and after, per target
- Releases applied and their key changes
- Claude Code plugin state and whether `/reload-plugins` is still pending
- Migration steps executed or still pending
- Files updated or backed up
- Commands that could not run and why
- User next actions, if any
