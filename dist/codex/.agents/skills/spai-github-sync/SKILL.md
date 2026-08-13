---
name: spai-github-sync
description: "Use when synchronizing this repository's GitHub setup: main/develop branch existence and branch protection for the CLI release flow. Do not use for creating a release."
---

# GitHub Sync

Use this repository skill only for setup and synchronization of GitHub repository settings.

## Scope

- Branches: `main`, `develop`.
- Branch protection for `main` and `develop`: direct pushes allowed, force pushes and deletion blocked.
- Local guard: a git `pre-push` hook that blocks force pushes to and deletion of `main`/`develop` and restricts direct `main` pushes to the release fast-forward (`develop:main`). Local defense only; server-side protection stays the final barrier.
- No release-drafter files, no pull request template, no label sync; the release flow is CLI-driven (`github-release`) and does not use pull requests.
- Sync is convergent and idempotent: one run aligns the repository with the current model even when several SPAI versions were skipped. `spai-update` runs it after updating installed files.

## GitHub Profile

Before any `gh` command, resolve the host from `SPAI_GITHUB_HOST`, local `spai.githubHost`, then `github.com`, and resolve the profile from `SPAI_GITHUB_PROFILE`, then local `spai.githubProfile`. If a profile is configured, read its credential with `gh auth token --hostname <host> --user <profile>` without printing it and run every `gh` command with that credential through `GH_TOKEN` (`github.com` or `*.ghe.com`) or `GH_ENTERPRISE_TOKEN` (other hosts). Verify `gh api user --jq .login` matches the profile. Do not use `gh auth switch`; fall back to the globally active account only when neither the environment nor local config selects a profile.

## Phase Rules

For broad sync work, split into phases:

1. Inspect repository, working tree, remotes, and `gh` access.
2. Verify or create `develop` from `main`.
3. Apply branch protection.
4. Install or update the local pre-push guard.
5. Validate and report.

If a phase is blocked by permission, missing auth, unsupported repository plan, or required confirmation, complete safe earlier phases and report the remaining work.

## Safety Rules

- Do not force push.
- Do not delete branches.
- Do not delete labels without explicit confirmation.
- Do not create `.codex`, `.claude/skills`, or unrequested AI skill directories inside this repository.
- Keep repository skills under `.agents/skills`.
- Do not create releases or tags during sync.
- Never overwrite a user-authored `.git/hooks/pre-push`; replace it only with explicit confirmation and a `.bak` backup.
- Do not configure `core.hooksPath`; it would disable the user's other hooks.
- Do not rename the default branch or change the remote default branch without explicit confirmation.
- Preserve unrelated user changes.

## Procedure

1. Confirm the current directory is a git repository.
2. Check `git status --short --branch`.
3. Run `gh repo view` and `gh auth status`. If GitHub CLI is unavailable, unauthenticated, or lacks permission, report the remaining GitHub steps.
4. Confirm `main` exists locally and remotely when possible.
5. Confirm `develop` exists locally and remotely when possible. If missing, create it from `main` and push without force.
6. Protect `main` and `develop` with the same policy:
   - no required pull request reviews
   - no required status checks
   - force pushes disabled
   - deletion disabled
7. Install or update the local pre-push guard at `.git/hooks/pre-push`:
   - Skip with a pass log when the directory is not a git repository.
   - If the file is missing, write the script below verbatim and `chmod +x` it.
   - If the file exists and line 2 matches `# spai:pre-push v<N>`: rewrite it only when `<N>` is lower than the version below (idempotent).
   - If the file exists without that marker, it is the user's hook: stop this step, report it, and replace it only with explicit confirmation, keeping a `.bak` backup.
   - Never bypass the installed hook with `--no-verify`.

   ```sh
   #!/bin/sh
   # spai:pre-push v1
   # SPAI local guard. Blocks force pushes to and deletion of main/develop, and
   # direct pushes to main that do not come from develop. Server-side branch
   # protection remains the final defense. Do not bypass with --no-verify.

   zero=0000000000000000000000000000000000000000

   while read -r local_ref local_sha remote_ref remote_sha; do
     case "$remote_ref" in
       refs/heads/main|refs/heads/develop) ;;
       *) continue ;;
     esac

     if [ "$local_sha" = "$zero" ]; then
       echo "spai pre-push: deleting $remote_ref is blocked. Protected branches are never deleted." >&2
       exit 1
     fi

     if [ "$remote_ref" = "refs/heads/main" ] && [ "$local_ref" != "refs/heads/develop" ]; then
       echo "spai pre-push: direct push to main is blocked. Release with: git push origin develop:main" >&2
       exit 1
     fi

     if [ "$remote_sha" != "$zero" ] && git cat-file -e "$remote_sha" 2>/dev/null; then
       if ! git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
         echo "spai pre-push: non-fast-forward push to $remote_ref is blocked. Never force push a protected branch." >&2
         exit 1
       fi
     fi
   done

   exit 0
   ```

8. If legacy release-drafter files exist (`.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`), report them as removal candidates; remove them only with explicit confirmation.

## Final Report

Keep reports short and include:

- Branches created or already present
- Branch protection status
- Local pre-push guard: installed | updated | already current | blocked by user hook
- Legacy release-drafter files found, if any
- Commands that could not run and why
- User next actions, if any
