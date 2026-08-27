---
name: jig-doctor
description: "Use when diagnosing every detected jig installation for Claude Code, Codex, and Antigravity across current project and user scopes, plus repository profile, migration, protection, guard, rubric, and legacy state. Read-only; fixes are delegated to project-setup, jig-update, github-sync, and version-rubric."
---

# jig Doctor

Use this repository skill to diagnose the installed jig state across every supported target and scope. This skill never modifies files or settings.

## Distribution Model

Each CLI is installed on its own, but diagnosis inventories all of them before judging any one instance.

- **Claude Code plugin** is host-managed and may be enabled at project, local, user, or managed scope. Its skills are namespaced as `/jig:<skill>` and its host version is not compared with file payload tags.
- **Claude Code standalone** is a compatibility installation under `.claude/skills` or `~/.claude/skills`. A current installation has a `.jig-installation` ledger plus per-skill `.jig-provenance`; a verified legacy copy may have no ledger yet.
- **Codex and Antigravity** have no plugin system. Their project and global rules files carry independent managed blocks and version stamps; skill roots differ by target and scope.

## Installation Inventory

Use this exact contract, shared with `jig-update`. Inventory all rows before deciding that jig is absent or healthy.

<!-- jig:start installation-inventory -->
| Target | Scope | Installation evidence |
|---|---|---|
| Claude Code | project | `jig@jig` enabled in `.claude/settings.json` |
| Claude Code | local | `jig@jig` enabled in `.claude/settings.local.json` |
| Claude Code | user | `jig@jig` enabled in `~/.claude/settings.json` |
| Claude Code | managed | `jig@jig` reported at managed scope by `claude plugin list --json` |
| Claude Code standalone | project | valid `.jig-installation` or verified legacy jig skill set under `./.claude/skills` |
| Claude Code standalone | user | valid `.jig-installation` or verified legacy jig skill set under `~/.claude/skills` |
| Codex | project | jig managed block in `./AGENTS.md` |
| Codex | global | jig managed block in `~/.codex/AGENTS.md` |
| Antigravity | project | jig managed block in `./GEMINI.md` |
| Antigravity | global | jig managed block in `~/.gemini/GEMINI.md` |
<!-- jig:end installation-inventory -->

Use `scripts/inspect-claude-standalone.sh` from this skill once for each standalone root. It reports `absent`, `source-mirror`, `verified`, `legacy-unledgered`, `ledger-invalid`, `partial`, `provenance-conflict`, or `non-owned` without writing anything. Only verified and legacy-unledgered roots count as update-compatible installations; the other non-absent states are diagnostic context with an explicit finding.

## GitHub Profile

Before any `gh` command, resolve the host from `JIG_GITHUB_HOST`, local `jig.githubHost`, then `github.com`, and resolve the profile from `JIG_GITHUB_PROFILE`, then local `jig.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Checks

1. **Complete installation inventory**: inspect all ten rows in the shared contract, regardless of which agent invoked the skill.
   - Use `claude plugin list --json` as the primary plugin inventory. Use project, local, and user settings as fallback and to prove those exact scopes; an unscoped text match proves only that the plugin exists. Report host-managed version data without comparing it with file payload tags. If the CLI and every settings source are unavailable, mark only that plugin inventory as skipped.
   - Run the standalone inspector for both project and user roots. `non-owned` means an ordinary user skill root and is not a jig defect. `source-mirror` means the jig repository's development copy and is not an installed payload. Report `legacy-unledgered`, `ledger-invalid`, `partial`, and `provenance-conflict` distinctly; the latter three belong to `jig-update` but must remain untouched by doctor.
   - Detect Codex project/global and Antigravity project/global independently from each rules file's own jig managed block. File existence alone is not installation evidence. Read the version and `skills=` from that same block; a stamp without `skills=` means the full default set.
   - Skill roots are target- and scope-specific: project Codex and Antigravity use `./.agents/skills`, global Codex uses `~/.agents/skills`, and global Antigravity uses `~/.gemini/config/skills`. Shared project files do not merge the two rules-file instances.
2. **Version and selection, per instance**: resolve the latest release tag once (`gh api repos/0x0w1/jig/releases/latest --jq .tag_name`) and report each detected instance independently.
   - Claude Code plugin: host-managed version and plugin-managed selection.
   - Claude Code standalone: ledger `version` and exact `<manifest skill>=<directory>` mappings. A verified legacy root has unknown version and selection until its first successful `jig-update`; do not claim it is current.
   - Codex and Antigravity: that instance's rules-file stamp and `skills=` selection. Never reuse the first stamp found for another target or scope.
3. **Drift and provenance, per instance**:
   - Claude Code plugin is updated by the host; verify enabled state but do not compare plugin files.
   - For each versioned file installation, read that version's `dist/files.tsv`. A missing catalog means the release shipped `SKILL.md` only. Compare every selected payload path and report missing and mismatched files separately. `main`, `custom`, and unknown versions cannot prove fixed-payload drift.
   - Codex payload path: `dist/codex/.agents/skills/jig-<skill>/<path>`. Antigravity uses its matching distribution path. Resolve the installed root from the inventory row rather than assuming project scope.
   - Standalone unprefixed mappings such as `github-sync=github-sync` compare with the Claude Code plugin payload. Prefixed mappings such as `github-sync=jig-github-sync` compare with the Codex payload. Before comparing content, require the ledger mapping, skill directory, `SKILL.md`, and exact `.jig-provenance` to agree; use the inspector status as the finding category.
   - A payload mismatch is drift. A missing selected file is a partial installation. A file the payload does not list is a leftover. Report leftovers without deleting them; only `jig-update` may remove one, with confirmation.
4. **Pending migrations, per versioned instance**: for each installed version behind latest, read every newer release note (`gh release view <tag> --repo 0x0w1/jig`), then merge and de-duplicate the needed items while retaining the affected target/scope list.
   - Count **line-anchored markers only** (`^<!-- jig:start migration-auto -->$` and `^<!-- jig:start migration-manual -->$`); notes often name these markers in prose, and a substring search would count those mentions as blocks.
   - Report the counts and quote the manual items in full; those need a human decision and are what makes a release `major`.
   - Do not evaluate whether an item was already applied and never run one. `jig-update` owns execution.
   - Skip this check when an instance has no installed version or is already latest.

Checks 5–10 diagnose repository state, not global installation state. Run them only when the current directory is a Git worktree and at least one project-scoped jig instance belongs to that repository. A user/global-only inventory must not turn whichever directory happens to be current into the diagnostic target; report repository checks as not applicable instead.
5. **Branch protection** (optional feature — absence is not automatically a defect): `gh api repos/<owner>/<repo>/branches/<branch>/protection` for `main` and `develop`. Expected when it is in place: no required pull request reviews, no required status checks, `allow_force_pushes.enabled == false`, `allow_deletions.enabled == false`.

   Read the answer before judging it:

   | Response | Meaning | Report as |
   |---|---|---|
   | `200` with the expected policy | Protected | OK |
   | `200` with a different policy | Drifted from the model | Finding → `github-sync` |
   | `403` | The plan does not include protection for this repository (a private repository on the free plan), or the profile has no admin permission | Not available — informational, **never a defect** |
   | `404`, and `git config --local --get jig.branchProtection` is `skipped` | The user declined it on this checkout | Skipped by choice — informational |
   | `404`, no recorded choice | Available but never set up | Finding → `github-sync` offers it |

   Distinguish `403` from `404`. Branch protection on a private repository requires a paid plan, so most personal projects answer `403`, and reporting that as "unprotected" turns a plan limit into a permanent red mark.

   When protection is absent for any reason, check whether a ruleset covers the branches instead: `gh api repos/<owner>/<repo>/rulesets`. A `403` here means the same plan limit — report the check as skipped. jig never creates or edits rulesets; a repository governed by one is reported as protected by a ruleset and left alone.

   Whenever the branches are not protected server-side, say in the report that the local `pre-push` guard is the only barrier left.
6. **Branch state**: after `git fetch origin --prune`, run `git rev-list --left-right --count origin/main...origin/develop`. If `main` is ahead of `develop` (left count > 0), the next release cannot fast-forward; report it.
7. **Legacy leftovers** (report existence only):
   - `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`
   - labels `patch`, `minor`, `major`, `enhancement`, `fix`, `chore` (`gh label list`)
   - leftover backups: `find . -name "*.bak" -not -path "./.git/*"`
8. **Local pre-push guard**: inspect `.git/hooks/pre-push`.
   - Missing file, or line 2 not matching `# jig:pre-push v<N>`: the guard is not installed (an unmarked file is the user's own hook — never report it as drift).
   - Marked but `<N>` lower than the latest guard version (`v1`): outdated.
   - Marked but missing `merge-base --is-ancestor` or `refs/heads/main`, or not executable: locally modified or broken.
   - Fix owner is `github-sync`; report, never modify.
9. **GitHub profile**: report whether the profile came from `JIG_GITHUB_PROFILE`, local `jig.githubProfile`, or the globally active fallback. When a profile is configured, verify its stored credential and `gh api user` identity without printing the token. A missing credential, identity mismatch, or missing local profile for a multi-account host is a `project-setup` finding.

10. **Version rubric**: resolve the path from `JIG_VERSION_RUBRIC`, then local `jig.versionRubric`, then `.jig/versioning.md`.
   - Report the source. A path from the environment variable is session-only; say so.
   - Report the kind from the file's `> Basis:` line (`> 기준:` in a legacy rubric): adopted default or project-specific.
   - Check the two required sections. Accept either spelling: `## Decision Order` or `## 판정 순서`, and `## Grade Definitions` or `## 등급 정의`. A missing one is a contract break: `github-release` stops on it.
   - Report which spelling the file uses. Korean titles are legacy but valid, so report them as legacy, never as drift or as a defect. A file that mixes the two spellings is a contract break, because one required section is then missing under both names.
   - Check that the file is committed (`git ls-files --error-unmatch <path>`). An untracked or uncommitted rubric does not reach clones or CI, so releases grade differently for different people.
   - A missing file is information, not a defect. Fix owner is `version-rubric`.
   - Never compare the rubric with any payload: it is user-owned content, never drift.

## Legacy Names (pre-rename installs)

The project was called `spai` before it was renamed to `jig`. An installation from that era carries the old names, and every check below must recognize them and report them as **legacy, not as drift or a defect.**

| Surface | Legacy | Current |
|---|---|---|
| Skill directories | `.agents/skills/spai-*` | `.agents/skills/jig-*` |
| Plugin | `spai@spai` | `jig@jig` |
| Slash names | `/spai:<skill>` | `/jig:<skill>` |
| Managed block | `<!-- spai:start ... -->` | `<!-- jig:start ... -->` |
| Version stamp | `<!-- spai:version ... -->` | `<!-- jig:version ... -->` |
| Environment | `SPAI_*` | `JIG_*` |
| Local config | `spai.githubProfile`, `spai.versionRubric`, `spai.branchProtection` | `jig.*` |
| Rubric file | `.spai/versioning.md` | `.jig/versioning.md` |
| Push guard | `# spai:pre-push v<N>` | `# jig:pre-push v<N>` |

- Report which names the installation uses. Mixed state is normal mid-migration and is not a defect by itself.
- The fix owner for a legacy installation is `jig-update`. Never migrate anything from this skill; it is read-only.
- `.spai/versioning.md` is project-owned content. Report it as legacy and never as drift, exactly like `.jig/versioning.md`.

## Safety Rules

- Read-only: do not modify files, settings, branches, or labels.
- Do not run the installer or any `claude plugin` command that changes state; recommend `jig-update` instead.
- Report the exact command for each recommended fix, but do not execute it.
- Never report a skill the user wrote as a jig problem. A standalone `non-owned` root is informational, not an installation or defect; jig owns only ledger/provenance-verified standalone mappings, the `jig` plugin, and `jig-` prefixed directories tied to a managed block.
- Never report the contents of `.jig/` as drift or as a jig defect. That directory is owned by the project.
- Preserve unrelated user changes.

## Procedure

1. Run the complete installation inventory first. Invoke the standalone inspector for both roots, inspect all plugin sources, and read all four Codex/Antigravity rules files. Record absent and non-owned rows separately from detected instances.
2. Resolve available tools and repository context: `command -v claude`, `gh auth status`, and, only for project-scoped instances, `git rev-parse --is-inside-work-tree` plus `gh repo view`. If a tool is unavailable, run checks that do not need it and list the skipped checks.
3. Run checks 2–4 independently for every detected instance. Run checks 5–10 once for the current repository only when the repository-state applicability rule is satisfied.
4. Compose the report. For every finding, name the fix owner:
   - version behind, drifted or partial files, invalid standalone ledger/provenance, a disabled or partial plugin at an already detected scope, or pending `migration-auto` items → `jig-update`
   - pending `migration-manual` items → `jig-update`, but only after the user decides each item
   - protection mismatch, or protection available but never set up → `github-sync` (deletions only with explicit confirmation)
   - protection unavailable on this plan, or skipped by choice → no action; do not recommend a fix for something the repository cannot have or the user declined
   - local guard missing, outdated, or modified → `github-sync`
   - GitHub profile missing, ambiguous, or invalid → `project-setup`
   - version rubric missing, contract-broken, or uncommitted → `version-rubric`
   - branch state divergence → stop releases and reconcile manually; never force-push.

## Final Report

Write the report in the language the repository already uses for its own documents, defaulting to English.

```md
## jig Diagnostic Report

### Installation inventory
| Target | Scope | Model | Status | Version | Selection |
|---|---|---|---|---|---|
| Claude Code | project | plugin | enabled | host-managed | plugin-managed |
| Claude Code | user | standalone | verified | <ledger version> | <skill=directory mappings> |
| Codex | global | managed files | current | <stamp> | <skills> |

### Drift and provenance
- <target>/<scope>: clean | missing files | drifted files | legacy-unledgered | ledger-invalid | partial | provenance-conflict

### Pending migrations
- <affected target/scopes>: auto N | manual N (items quoted in full) | none

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
