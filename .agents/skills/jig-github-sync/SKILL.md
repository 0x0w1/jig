---
name: jig-github-sync
description: "Use when synchronizing this repository's GitHub setup: main/develop branches, optional branch protection, and the managed local guards (the git pre-push hook plus the native Codex and Antigravity push hooks), including guard cleanup before uninstalling jig. Do not use for creating a release."
---

# GitHub Sync

Use this repository skill only for setup and synchronization of GitHub repository settings.

## Scope

- Branches: `main`, `develop`.
- Branch protection for `main` and `develop`: **optional**, and only when the repository can have it. Direct pushes allowed, force pushes and deletion blocked. See Branch Protection Is Optional.
- Local guard, first layer: a git `pre-push` hook installed from `assets/pre-push` by `scripts/manage-pre-push.sh`. It blocks force pushes to and deletion of `main`/`develop` and restricts direct `main` pushes to the release fast-forward (`develop:main`) and the hotfix landing (`hotfix/<slug>:main`, owned by `hotfix-flow`). Local defense only; server-side protection stays the final barrier.
- Local guard, second layer: the same policy as a `PreToolUse` hook that inspects the push command before it runs, `--no-verify` included, which a git hook cannot see. Claude Code ships it inside the `jig` plugin. For Codex (`.codex/hooks.json`) and Antigravity (`.agents/hooks.json`) this skill installs the hook entry with `scripts/manage-native-hooks.sh`; the entry runs the shipped `assets/guard-push.sh`. Project scope only — a user-scope entry would guard repositories jig is not installed in.
- No release-drafter files, no pull request template, no label sync; the release flow is CLI-driven (`github-release`) and does not use pull requests.
- Sync is convergent and idempotent: one run aligns the repository with the current model even when several jig versions were skipped. `jig-update` runs it after updating installed files.

## Branch Protection Is Optional

GitHub gives branch protection to public repositories on every plan, but a **private repository needs a paid plan** (Pro, Team, or Enterprise). On a private repository on the free plan the API answers `403`, and so does the rulesets API. That is the normal state for most personal projects, not a defect.

So protection is never applied silently. Probe first, ask second, and treat "not available" as a pass.

**Probe** (read-only, before touching anything):

```bash
gh api repos/<owner>/<repo> --jq '{private: .private, admin: .permissions.admin}'
```

| Probe result | Meaning | What to do |
|---|---|---|
| `admin: false` | The profile cannot change settings on this repository | Skip. Report it as a permission limit, not a failure |
| `private: false` | Public repository — protection is available on every plan | Ask |
| `private: true`, protection API answers `403` | Private repository without a plan that includes protection | Skip. Say so in one line and move on |
| `private: true`, protection API answers `200` or `404` | Paid plan — protection is available | Ask |

Confirm the private case against the API rather than guessing a plan from `gh api user`; the plan on the account is not always the plan that governs the repository.

**Ask, once:**

> This repository is public (or on a plan that includes it), so `main` and `develop` can be protected against force pushes and deletion. Set that up now?

- Yes → apply the policy in Procedure step 6, then record `git config --local jig.branchProtection enabled`.
- No → record `git config --local jig.branchProtection skipped` and continue. The local `pre-push` guard still covers force pushes, deletion, and direct pushes to `main` on this machine.
- Already protected with the policy in Procedure step 6 → record `enabled` and do not ask. The repository is already where the answer would put it, so the question has nothing to decide.
- Already recorded → do not ask again. `enabled` re-applies the policy convergently; `skipped` skips with a one-line log. Re-ask only when the user asks to change it.

`jig.branchProtection` lives in `.git/config`, so it does not reach clones or CI. It records a choice about this checkout, not a repository contract; a collaborator is asked separately on their own machine.

**Without server-side protection, the local guard is the only barrier.** Say that plainly in the report when protection is skipped or unavailable, because a `--no-verify` push then reaches `main` with nothing in the way.

## GitHub Profile

Before any `gh` command, resolve the host from `JIG_GITHUB_HOST`, local `jig.githubHost`, then `github.com`, and resolve the profile from `JIG_GITHUB_PROFILE`, then local `jig.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Phase Rules

For broad sync work, split into phases:

1. Inspect repository, working tree, remotes, and `gh` access.
2. Verify or create `develop` from `main`.
3. Apply branch protection when it is available and the user wants it.
4. Install or update the local guards: the `pre-push` hook, then the native hook entry for each detected Codex or Antigravity installation.
5. Validate and report.

If a phase is blocked by permission, missing auth, unsupported repository plan, or required confirmation, complete safe earlier phases and report the remaining work.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not delete labels without explicit confirmation.
- Do not create `.claude/skills` or unrequested AI skill directories inside this repository. `.codex/` is created only as `.codex/hooks.json`, only by the native hook manager, and only when `AGENTS.md` carries the Codex jig stamp.
- Keep repository skills under `.agents/skills`.
- Never rewrite a user's entry in `.codex/hooks.json` or `.agents/hooks.json`. The manager adds, updates, or removes only the entry it marks as its own (`statusMessage` `jig guard-push` for Codex, the `jig-guard-push` group for Antigravity), preserves everything else, and refuses a file it cannot parse or a symlink.
- Never grant Codex hook trust on the user's behalf. Codex runs a hook only after the user reviews it in `/hooks`; report that step, do not perform it.
- Do not create releases or tags during sync.
- Never overwrite a user-authored `.git/hooks/pre-push`; pass `--replace-user-hook` only after explicit confirmation. The manager preserves it as `.git/hooks/pre-push.jig-user-backup` and restores it when the jig guard is uninstalled.
- Do not configure `core.hooksPath`; it would disable the user's other hooks.
- Do not rename the default branch or change the remote default branch without explicit confirmation.
- Preserve unrelated user changes.

## Procedure

1. Confirm the current directory is a git repository.
2. Check `git status --short --branch`.
3. Run `gh repo view` and `gh auth status`. If GitHub CLI is unavailable, unauthenticated, or lacks permission, report the remaining GitHub steps.
4. Confirm `main` exists locally and remotely when possible.
5. Confirm `develop` exists locally and remotely when possible. If missing, create it from `main` and push without force.
6. Settle branch protection per Branch Protection Is Optional: probe, then ask unless `jig.branchProtection` already records a choice. When applying, protect `main` and `develop` with the same policy:
   - no required pull request reviews
   - no required status checks
   - force pushes disabled
   - deletion disabled

   A `403` from the protection API at this point means the plan does not include it. Skip, log one line, and continue with the remaining steps; never retry it as an error. jig does not configure rulesets — a repository already governed by a ruleset is left alone.
7. Install or update the local guard by running `scripts/manage-pre-push.sh install` relative to this skill directory.
   - The manager copies the shipped `assets/pre-push` source atomically to the repository's default `.git/hooks/pre-push` path and makes it executable.
   - Re-running it is idempotent. It repairs permissions and replaces a marked jig hook when its payload drifted or its version is old.
   - An unmarked file is the user's hook. Stop and ask; after explicit confirmation only, rerun with `install --replace-user-hook`. The manager keeps the user hook separately for uninstall restoration.
   - If `core.hooksPath` is set, the manager refuses to write into that user-managed hook directory. Report the configured path and leave it unchanged.
   - Never bypass the installed hook with `--no-verify`.

8. Install or update the native push hook by running `scripts/manage-native-hooks.sh install` relative to this skill directory.
   - Hosts are detected from the jig managed block in `./AGENTS.md` (Codex → `.codex/hooks.json`) and `./GEMINI.md` (Antigravity → `.agents/hooks.json`). An undetected host gets no file. Claude Code needs nothing here: its plugin carries the same hook.
   - The entry runs the shipped `assets/guard-push.sh` through a repository-relative command, so a payload update by `jig-update` refreshes the guard without changing the entry.
   - Re-running is idempotent and answers `installed`, `added entry`, `updated entry`, or `already current`. Other entries in the file are preserved. Merging into an existing file needs `jq`; without it the manager writes only a fresh file and otherwise stops with a message instead of guessing.
   - A user-owned entry that already points at the guard is reported and left alone.
   - **Codex trusts hooks per definition.** After the entry is added or updated, Codex runs it only once the user has reviewed and trusted it in `/hooks`. Say so in the report every time; jig cannot grant that trust.
   - Antigravity reads only the hook's stdout JSON and treats a crash as allow, so the guard answers `{"decision":"deny"}` there rather than exiting non-zero.
   - The Codex contract was verified live (`codex exec` runs the project hook, passes `tool_input.command`, honors exit 2). The Antigravity entry follows the documented contract; on the first Antigravity installation, confirm that `git push --no-verify origin main` is refused and report if it is not.

9. If legacy release-drafter files exist (`.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`), report them as removal candidates; remove them only with explicit confirmation.

## Uninstall Cleanup

When the user asks to uninstall `github-sync` or all of jig from the current project, run `scripts/manage-native-hooks.sh uninstall` and then `scripts/manage-pre-push.sh uninstall`, both relative to this skill directory and both **before** removing the skill or plugin — once the skill directory is gone, the native entry points at nothing:

- The native hook manager removes only its own entry from `.codex/hooks.json` and `.agents/hooks.json`. A file that held nothing else is removed, and an emptied `.codex/` directory with it; a file with user entries keeps them.
- A hook whose line 2 carries the valid `# jig:pre-push v<N>` ownership marker is removed.
- If jig replaced a confirmed user hook, the manager restores `.git/hooks/pre-push.jig-user-backup` instead of leaving the path empty.
- An unmarked hook is never removed.
- A global/user-scope skill uninstall cannot safely discover every clone where the guards were installed. Clean each project checkout explicitly and report this limit.

## Final Report

Keep reports short and include:

- Branches created or already present
- Branch protection: applied | skipped by choice | not available (private repository without a plan that includes it) | not permitted (no admin) — and, when it is not in place, that the local guard is the only barrier
- Local pre-push guard: installed | updated | already current | blocked by user hook
- Native push hook, per detected host: installed | added entry | updated entry | already current | user entry | host not detected | blocked (jq missing, invalid JSON, symlink) — and, for Codex, that trusting the entry in `/hooks` is still the user's step
- Legacy release-drafter files found, if any
- Commands that could not run and why
- User next actions, if any
