---
name: project-setup
description: Use when onboarding SPAI into a repository, installing or repairing the SPAI skill set for Claude Code, Codex, or Antigravity, and selecting the GitHub CLI profile for that repository through SPAI_GITHUB_PROFILE or local git config without changing the globally active gh account.
---

# Project Setup

Install the requested SPAI target and bind GitHub operations to a repository profile. Store only the profile login and host; keep credentials in the GitHub CLI credential store.

## Profile Contract

Resolve the GitHub profile in this order:

1. An explicit profile supplied by the user or `--github-profile`.
2. `SPAI_GITHUB_PROFILE` environment variable.
3. `git config --local --get spai.githubProfile`.
4. An authenticated profile whose login matches the current repository owner.

Resolve the host from `SPAI_GITHUB_HOST`, then `git config --local --get spai.githubHost`, then `github.com`.

- Treat the environment variable as an ephemeral override; do not replace local config when it is present unless the user asks.
- Otherwise persist the selected login with `git config --local spai.githubProfile <profile>` and the host with `git config --local spai.githubHost <host>`.
- Never put an OAuth token in git config, tracked files, `.env`, logs, or reports.
- Validate the profile with `gh auth token --hostname <host> --user <profile>` without printing the result, then run `gh api user --jq .login` using that token through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts).
- Do not use `gh auth switch`; it changes the globally active profile and makes parallel repositories interfere with each other.
- If the requested profile is not authenticated, run `gh auth login --hostname <host>` interactively, then validate the exact profile again.

## Procedure

1. Inspect the repository and current installation:
   - confirm the working directory and git repository
   - inspect `claude plugin list`, `AGENTS.md`, and `GEMINI.md` as available
   - detect the requested target and scope; default to project scope and install one target per run; map SPAI global scope to Claude Code user scope
2. Resolve and validate the GitHub profile using the Profile Contract. If multiple authenticated profiles remain plausible, ask before selecting one.
3. Configure the profile:
   - keep an existing `SPAI_GITHUB_PROFILE` as the session override
   - otherwise write the repository-local `spai.githubProfile` and `spai.githubHost` values
4. Install or repair the selected target:
   - Claude Code: `claude plugin marketplace add 0x0w1/spai --scope <project|user>`, then `claude plugin install spai@spai --scope <project|user>`; use `user` for a requested global install and pass an already-installed plugin as healthy
   - Codex or Antigravity: `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh | SPAI_GITHUB_PROFILE=<profile> SPAI_GITHUB_HOST=<host> sh -s -- --target <target> --scope <scope>`; preserve the stamped skill selection when repairing an existing install
5. Verify:
   - Claude Code: `claude plugin list` shows `spai@spai` enabled
   - Codex: `AGENTS.md` has the SPAI version stamp and `.agents/skills/spai-project-setup/SKILL.md` exists
   - Antigravity: `GEMINI.md` has the stamp and the same skill file exists
   - the configured profile resolves to the expected login without changing the globally active `gh` account
6. Run `github-sync` for repository convergence, then `spai-doctor` for a read-only health check.

## Safety Rules

- Do not expose or persist tokens outside the GitHub CLI credential store.
- Do not modify shell startup files to persist environment variables.
- Do not overwrite locally modified skills without following installer backup rules.
- Do not force push, delete branches, or create a release.
- Preserve unrelated repository and GitHub settings.

## Final Report

Include:

- Target and scope installed or already healthy
- Profile source: environment | local git config | explicit selection | repository owner
- Profile login and host, never its token
- Files and local config keys changed
- `github-sync` and `spai-doctor` results
- Skipped or blocked steps and the exact next action
