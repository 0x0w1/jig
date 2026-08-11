---
name: spai-update
description: Use when updating the SPAI skills installed in this repository to the latest SPAI release by comparing the installed spai:version stamp with the latest GitHub release, summarizing the changes, re-running the installer pinned to the latest tag, and converging repository settings with github-sync.
---

<!-- spai:owned skill=spai-update -->

# SPAI Update

Use this repository skill to update the installed SPAI procedures to the latest release.

## Update Model

- The installed version and skill selection are stamped inside the SPAI managed block as `<!-- spai:version vX.Y.Z flow=solo-cli skills=<a,b,c> -->` in `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`. A stamp without `skills=` means the full default skill set. `solo-cli` is the only flow; a stamp naming another flow comes from a removed profile and updates to the current defaults.
- The latest version is the latest GitHub release tag of `0x0w1/spai`.
- An update re-runs `install.sh` pinned to the latest tag. The installer is idempotent: unchanged files pass, changed files are backed up as `*.bak`, and managed blocks are replaced in place.
- Repository-side convergence (branch protection, legacy release-drafter file and label cleanup) is handled by the `github-sync` skill after the file update, and is idempotent across skipped versions.
- A `major` version jump means the release flow or repository policy changed; read the `### Migration` sections of the release notes before updating.

## Safety Rules

- Do not force push.
- Do not run the installer with `--force` unless the user explicitly asks for a full template replacement.
- Do not delete branches, labels, or files without explicit confirmation; leave `*.bak` backups in place.
- Do not create releases or tags.
- Stop and report if the installer fails or the version stamp does not update.
- Preserve unrelated user changes.

## Procedure

1. Read the installed version stamp:
   - `grep -h "spai:version" CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null | head -n 1`
   - A missing stamp means an install without a version stamp; continue and treat the installed version as unknown.
2. Determine the latest release:
   - `gh api repos/0x0w1/spai/releases/latest --jq .tag_name`
   - Fallback without `gh`: `curl -fsSL https://api.github.com/repos/0x0w1/spai/releases/latest` and read `tag_name`.
3. If the installed stamp equals the latest tag, report up to date and stop.
4. Collect the release notes between the installed version and the latest:
   - `gh release list --repo 0x0w1/spai --limit 20`
   - `gh release view <tag> --repo 0x0w1/spai` for each release newer than the installed version.
   - Extract any `### Migration` sections.
5. Report the version delta with a short Korean summary of the changes and highlight migration steps. Ask for approval before applying, unless the user already asked for the update to be executed end to end.
6. Determine the GitHub account for the installer: the active `gh` account (`gh api user --jq .login`) or ask the user.
7. Detect the installed targets and re-run the installer pinned to the latest tag for each:
   - `./CLAUDE.md` with SPAI markers or `.claude/skills/` → `claude-code`
   - `./AGENTS.md` with SPAI markers → `codex`
   - `./GEMINI.md` with SPAI markers → `antigravity`
   - Command per target, preserving the stamped selection:
     `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh | sh -s -- --target <target> --scope project --github-account <account> --version <latest> --skills <stamped skills>`
   - When the stamp has no `skills=`, omit `--skills` so the installer applies the defaults. Never pass `--flow` with a value other than `solo-cli`; the installer rejects it.
8. Verify the stamp now shows the latest version.
9. Run the `github-sync` skill to converge branch protection and report legacy release-drafter files or labels; delete them only with explicit confirmation.
10. Run the `spai-doctor` skill to confirm the updated installation is healthy; include its findings in the report.
11. Report.

## Final Report

Keep reports short and include:

- Installed version before and after
- Releases applied and their key changes
- Migration steps executed or still pending
- Files updated or backed up
- Commands that could not run and why
- User next actions, if any
