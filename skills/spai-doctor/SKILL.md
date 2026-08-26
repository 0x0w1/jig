---
name: spai-doctor
description: "Use when diagnosing the SPAI installation in this repository: verify the Claude Code plugin, GitHub profile selection, installed version and skill drift, pending migrations, branch protection, local guard, and legacy leftovers. Read-only; fixes are delegated to project-setup, spai-update, and github-sync."
---

# SPAI Doctor

Use this repository skill to diagnose the installed SPAI state. This skill never modifies files or settings.

## Distribution Model

Each CLI is installed on its own; there is no combined install.

- **Claude Code** installs the `spai` plugin from the Claude Code marketplace. Its skills are namespaced by the host as `/spai:<skill>` and live under the plugin directory, never under `.claude/skills`. There is no installer, no `CLAUDE.md` managed block, and no version stamp: the host owns install, update, and removal.
- **Codex and Antigravity** have no plugin system, so `install.sh` copies `spai-` prefixed skill directories under `.agents/skills` and writes a managed block with a `<!-- spai:version ... -->` stamp into `AGENTS.md` or `GEMINI.md`.

## GitHub Profile

Before any `gh` command, resolve the host from `SPAI_GITHUB_HOST`, local `spai.githubHost`, then `github.com`, and resolve the profile from `SPAI_GITHUB_PROFILE`, then local `spai.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Checks

1. **Claude Code plugin**: only when the repository is used with Claude Code.
   - `claude plugin list` (or the `enabledPlugins` entry in `.claude/settings.json`) must show `spai@spai`.
   - `.claude/settings.json` should carry the marketplace under `extraKnownMarketplaces`. For project scope this is what shares the plugin with collaborators.
   - Report a missing entry with the exact fix: `/plugin marketplace add 0x0w1/spai` then `/plugin install spai@spai`.
   - The plugin version is host-managed; report it as reported by `claude plugin list` and do not compare it against the codex/antigravity stamp.
   - If the `claude` CLI is unavailable and `.claude/settings.json` has no plugin entry, report the check as skipped rather than as a failure.
2. **Version** (codex and antigravity): read the installed stamp (`grep -h "spai:version" AGENTS.md GEMINI.md 2>/dev/null | head -n 1`) and compare with the latest release tag (`gh api repos/0x0w1/spai/releases/latest --jq .tag_name`). Also read `skills=` from the stamp; a stamp without it means the full default skill set, and a missing stamp means an install without a version stamp. Skip this check when neither file carries the managed block.
3. **Drift** (codex and antigravity only; the Claude Code plugin is updated by the host): for each installed skill file, compare with the payload of the stamped version.
   - A skill is a directory, not always one file. Read the payload file list first (`curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/<stamp>/dist/files.tsv`); each row is `<skill>\t<path relative to the skill directory>`. A version that publishes no `files.tsv` shipped single-file skills, so compare `SKILL.md` alone.
   - codex: `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/<stamp>/dist/codex/.agents/skills/spai-<skill>/<path> | cmp -s - .agents/skills/spai-<skill>/<path>`
   - antigravity: same with `dist/antigravity/.agents/skills/spai-<skill>/<path>`
   - A `cmp` mismatch means the file was locally modified or partially updated. If the stamp is `main` or `custom`, drift cannot be judged against a fixed payload; report that instead.
   - A file under an installed skill directory that the payload list does not contain is a leftover from an older version, not drift. Report it as a leftover and leave it: only `spai-update` removes it, and only with confirmation.
4. **Pending migrations**: when the stamp is behind the latest release, read the notes of every release newer than the stamp (`gh release view <tag> --repo 0x0w1/spai`) and count the items inside `<!-- spai:start migration-auto -->` and `<!-- spai:start migration-manual -->` blocks.
   - Count **line-anchored markers only** (`^<!-- spai:start migration-auto -->$`); notes often name these markers in prose, and a substring search would count those mentions as blocks.
   - Report the counts and quote the manual items in full; those need a human decision and are what makes a release `major`.
   - Do not evaluate whether an item was already applied and never run one. `spai-update` owns execution.
   - Skip this check when there is no stamp or the stamp is already the latest.
5. **Branch protection** (optional feature — absence is not automatically a defect): `gh api repos/<owner>/<repo>/branches/<branch>/protection` for `main` and `develop`. Expected when it is in place: no required pull request reviews, no required status checks, `allow_force_pushes.enabled == false`, `allow_deletions.enabled == false`.

   Read the answer before judging it:

   | Response | Meaning | Report as |
   |---|---|---|
   | `200` with the expected policy | Protected | OK |
   | `200` with a different policy | Drifted from the model | Finding → `github-sync` |
   | `403` | The plan does not include protection for this repository (a private repository on the free plan), or the profile has no admin permission | Not available — informational, **never a defect** |
   | `404`, and `git config --local --get spai.branchProtection` is `skipped` | The user declined it on this checkout | Skipped by choice — informational |
   | `404`, no recorded choice | Available but never set up | Finding → `github-sync` offers it |

   Distinguish `403` from `404`. Branch protection on a private repository requires a paid plan, so most personal projects answer `403`, and reporting that as "unprotected" turns a plan limit into a permanent red mark.

   When protection is absent for any reason, check whether a ruleset covers the branches instead: `gh api repos/<owner>/<repo>/rulesets`. A `403` here means the same plan limit — report the check as skipped. SPAI never creates or edits rulesets; a repository governed by one is reported as protected by a ruleset and left alone.

   Whenever the branches are not protected server-side, say in the report that the local `pre-push` guard is the only barrier left.
6. **Branch state**: after `git fetch origin --prune`, run `git rev-list --left-right --count origin/main...origin/develop`. If `main` is ahead of `develop` (left count > 0), the next release cannot fast-forward; report it.
7. **Legacy leftovers** (report existence only):
   - `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`
   - labels `patch`, `minor`, `major`, `enhancement`, `fix`, `chore` (`gh label list`)
   - leftover backups: `find . -name "*.bak" -not -path "./.git/*"`
8. **Local pre-push guard**: inspect `.git/hooks/pre-push`.
   - Missing file, or line 2 not matching `# spai:pre-push v<N>`: the guard is not installed (an unmarked file is the user's own hook — never report it as drift).
   - Marked but `<N>` lower than the latest guard version (`v1`): outdated.
   - Marked but missing `merge-base --is-ancestor` or `refs/heads/main`, or not executable: locally modified or broken.
   - Fix owner is `github-sync`; report, never modify.
9. **GitHub profile**: report whether the profile came from `SPAI_GITHUB_PROFILE`, local `spai.githubProfile`, or the globally active fallback. When a profile is configured, verify its stored credential and `gh api user` identity without printing the token. A missing credential, identity mismatch, or missing local profile for a multi-account host is a `project-setup` finding.

10. **Version rubric**: resolve the path from `SPAI_VERSION_RUBRIC`, then local `spai.versionRubric`, then `.spai/versioning.md`.
   - Report the source. A path from the environment variable is session-only; say so.
   - Report the kind from the file's `> Basis:` line (`> 기준:` in a legacy rubric): adopted default or project-specific.
   - Check the two required sections. Accept either spelling: `## Decision Order` or `## 판정 순서`, and `## Grade Definitions` or `## 등급 정의`. A missing one is a contract break: `github-release` stops on it.
   - Report which spelling the file uses. Korean titles are legacy but valid, so report them as legacy, never as drift or as a defect. A file that mixes the two spellings is a contract break, because one required section is then missing under both names.
   - Check that the file is committed (`git ls-files --error-unmatch <path>`). An untracked or uncommitted rubric does not reach clones or CI, so releases grade differently for different people.
   - A missing file is information, not a defect. Fix owner is `version-rubric`.
   - Never compare the rubric with any payload: it is user-owned content, never drift.

## Safety Rules

- Read-only: do not modify files, settings, branches, or labels.
- Do not run the installer or any `claude plugin` command that changes state; recommend `spai-update` instead.
- Report the exact command for each recommended fix, but do not execute it.
- Never report a skill the user wrote as a SPAI problem. SPAI only owns the `spai` plugin and `spai-` prefixed directories.
- Never report the contents of `.spai/` as drift or as a SPAI defect. That directory is owned by the project.
- Preserve unrelated user changes.

## Procedure

1. Confirm context: `git rev-parse --is-inside-work-tree`, `gh repo view`, `gh auth status`, `command -v claude`. If a tool is unavailable, run only the checks that do not need it and list the skipped checks in the report.
2. Run checks 1–10 in order and collect the results.
3. Compose the report. For every finding, name the fix owner:
   - version behind, drifted files, missing plugin, or pending `migration-auto` items → `spai-update`
   - pending `migration-manual` items → `spai-update`, but only after the user decides each item
   - protection mismatch, or protection available but never set up → `github-sync` (deletions only with explicit confirmation)
   - protection unavailable on this plan, or skipped by choice → no action; do not recommend a fix for something the repository cannot have or the user declined
   - local guard missing, outdated, or modified → `github-sync`
   - GitHub profile missing, ambiguous, or invalid → `project-setup`
   - version rubric missing, contract-broken, or uncommitted → `version-rubric`
   - branch state divergence → stop releases and reconcile manually; never force-push.

## Final Report

Write the report in the language the repository already uses for its own documents, defaulting to English.

```md
## SPAI Diagnostic Report

### Claude Code plugin
- Registered/enabled: OK | missing items and the recovery command (version is host-managed)

### Version (codex/antigravity)
- Installed: <stamp> / latest: <latest> → up to date or behind | not installed

### Drift (codex/antigravity)
- None | list of mismatched files

### Pending migrations
- auto: N | manual: N (items quoted in full) | none

### Branch protection (optional)
- main: OK | mismatches, item by item | not available (plan or permission) | skipped by choice | protected by a ruleset
- develop: same
- When not protected: the local pre-push guard is the only barrier

### Branch state
- OK | main is N commits ahead (fast-forward release not possible)

### Legacy leftovers
- None | list of what was found

### Local guard
- pre-push: OK vN | not installed | outdated (vN → vM) | modified or not executable | user's own hook

### GitHub profile
- <source>: <profile>@<host> → OK | credential missing | identity mismatch | globally active fallback

### Version rubric
- <path> (source: environment variable | local config | convention) · adopted default | project-specific · titles English | Korean (legacy) · required sections OK | missing · committed | uncommitted | file absent

### Recommended actions
- <fix owner>: <command or skill>
```
