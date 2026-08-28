# GitHub Repository Settings

[한국어](github-repository-settings.ko.md)

This document describes what `install.sh` (for Codex and Antigravity CLI) does on GitHub. Claude Code installs as a plugin and never goes through the installer, so profile selection and convergence happen afterwards through `/jig:jig-setup`.

Installing jig skills in project scope needs no GitHub profile. Installing without one only skips the GitHub repository settings sync; the installed `jig-setup` sets `JIG_GITHUB_PROFILE` or the local `jig.githubProfile` later. A profile's credential is passed per command through the environment and never changes the globally active account.

## Repository Rules

- Ordinary work starts from the current `origin/develop` on a `feature/*`, `fix/*`, or `chore/*` branch, and is finished by merging into `develop` locally with `git merge --squash` and pushing. No pull requests.
- Squash commit subjects on `develop` use a conventional prefix (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`).
- A release runs only when the user asks for one. It promotes `develop` to `main` with `git push origin develop:main` (fast-forward only), then creates the `vX.Y.Z` tag and the GitHub release from the CLI. No release PR, no `release/*` branch, no release-drafter.
- If a release request contains code, configuration, documentation, generated `dist`, or installer changes not yet merged into `develop`, the release stops and the ordinary work flow is completed first.

## What install.sh Applies

`install.sh --target <codex|antigravity> --scope project` installs the agent skill and rules files first. It attempts the GitHub work below only when a profile was already provided.

- Selecting the GitHub CLI account:
  - The profile resolves in order: `--github-profile` → `JIG_GITHUB_PROFILE` → local `jig.githubProfile`.
  - `--github-account` and `JIG_GITHUB_ACCOUNT` remain supported aliases.
  - If the given account is unknown to `gh`, it runs `gh auth login`.
  - It reads the credential with `gh auth token --user <profile>` and passes it to each `gh` command only. The token is never printed or written to a file.
  - A GitHub Enterprise host is set with `--github-host` or `JIG_GITHUB_HOST`.
- Local git user:
  - With `--configure-git-user` it prompts for `user.name` and `user.email` and stores them in `git config --local`.
  - With `--git-user-name` and `--git-user-email`, or `JIG_GIT_USER_NAME` and `JIG_GIT_USER_EMAIL`, it stores them non-interactively.
- Repository context:
  - `gh repo view --json visibility,viewerPermission` reports repository visibility and the current account's permission.
- Ensuring `develop`:
  - If `develop` does not exist on GitHub, it is created from the current commit of `main`.
  - An existing `develop` is left untouched.
- Branch protection:
  - `install.sh` never applies branch protection itself.
  - The `GUIDE` output points at the remaining manual step.

## Branch Protection Is Optional

**Branch protection is an optional feature.** GitHub gives it to public repositories on every plan, but a **private repository needs a paid plan** (Pro, Team, or Enterprise). On a private repository on the free plan, both the protection API and the rulesets API answer `403`. Most personal projects land there, and that is the boundary of the plan, not a defect.

So `github-sync` never applies it silently.

1. It reads `private` and `permissions.admin` from `gh api repos/<owner>/<repo>`.
2. If the repository cannot have protection, it logs one line and moves on. Not a failure.
3. If it can, it **asks once** — "this repository is public (or on a plan that includes it), so `main` and `develop` can be protected. Set that up now?"
4. The answer is recorded in `git config --local jig.branchProtection` as `enabled` or `skipped`, and the next sync does not ask again. The value lives in `.git/config`, so it does not reach clones; a collaborator answers separately on their own machine.

`jig-doctor` reads the same way. A `403` means "outside this plan" and is not a defect; a `404` with `skipped` recorded means the user declined. Neither produces a recommended action.

**Without protection, the local `pre-push` guard is the only barrier.** Both skills say so in their report.

jig never creates or edits rulesets. A repository already governed by one is left alone and reported as protected.

### The Policy That Gets Applied

Both `main` and `develop` forbid force pushes and branch deletion.

The same policy applies to both: no pull request required, no required status checks. `develop` takes the identical body at `branches/develop/protection`.

```bash
gh api -X PUT "repos/<owner>/<repo>/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
EOF
```

## When It Stops

An install that names a GitHub profile stops when that profile's `gh auth login` or credential verification cannot be completed. An install that names no profile never stops for this.

## When It Is Skipped

The installer skips the GitHub repository settings work and continues installing files when:

- `--scope global` is used
- `--dry-run` is used
- no GitHub profile has been settled yet
- `gh` is not installed
- `git` is not installed
- the current directory is not a git repository
- `gh repo view` cannot resolve the current repository
- the authenticated user cannot create branches

## Safety Boundaries

`install.sh` does not:

- create or delete labels
- delete branches by hand
- move or overwrite an existing branch
- create releases or tags
- force push
- change the default branch
- change repository visibility or ownership

## Legacy Cleanup

Older jig versions installed a release-drafter PR flow. If any of the following is left behind it is no longer used, and the `github-sync` skill can confirm and clean it up.

- `.github/drafter-config.yaml`
- `.github/workflows/drafter.yaml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- labels: `patch`, `minor`, `major`, `enhancement`, `fix`, `chore`
- the repository General setting `Automatically delete head branches` (no effect without pull requests)

## Verifying

To see the planned work without changing files or GitHub settings, use dry-run mode.

```bash
sh install.sh --target codex --scope project --dry-run
```

That validates the skill install plan without a profile. After installing, running `jig-setup` selects the profile, ensures `develop`, and settles branch protection. To wire up GitHub during the install, pass a profile:

```bash
sh install.sh --target codex --scope project --github-profile your-account
```

## The Local pre-push Guard

Separately from server-side protection, `github-sync` installs a local guard at `.git/hooks/pre-push`. It exists only in that clone, so a fresh clone needs `github-sync` run again.

- blocks force pushes (non-fast-forward) to `main` and `develop`
- blocks remote deletion of `main` and `develop`
- blocks direct pushes to `main` other than the `develop:main` fast-forward release

A git hook can be bypassed with `--no-verify`; that is its limit. jig skills forbid the bypass, and on Claude Code the `jig` plugin's PreToolUse hook blocks an offending push command — `--no-verify` included — before it runs. Server-side branch protection is the last line when the repository can have it; when it cannot, this guard is the only one. `jig-doctor` diagnoses it, and `github-sync` installs or refreshes it.
