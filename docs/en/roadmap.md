# jig Roadmap

[한국어](../ko/roadmap.md)

> A record of direction ideation. Candidates are kept together with their trigger conditions, whether or not they are being worked on.

## Identity

Early jig is **a harness setup tool for the CLI agents used on personal side projects.** The targets are Claude Code, Codex, and Antigravity CLI.

What separates it from a plain skill marketplace:

1. **It converges repository state too** — not only session skills, but the branch model, branch protection, and release discipline, managed by `github-sync` (convergence) and `jig-doctor` (diagnosis)
2. **Cross-agent consistency plus lifecycle** — one procedure source (`skills/`) rendered into several CLIs, with the version stamp, `jig-update`, and `jig-doctor` managing what happens after the install

## What Ships Today

- installer: installs pinned to the latest release tag, `--version` rollback, `--skills` selective install (the `manifest.tsv` catalog; codex and antigravity only)
- four workflow skills: `develop-task-flow` (ordinary work), `hotfix-flow` (a released defect that cannot wait for the `develop` queue), `github-release`, `github-sync`
- two lifecycle skills: `jig-update`, `jig-doctor`
- one onboarding skill: `jig-setup` (selects and verifies the per-repository GitHub profile after install)
- three documentation skills: `readme` (write or update a README), `version-rubric` (settle the version rubric and ship the per-type catalog), `rubric-scan` (scan the repository and recommend one)
- one repository housekeeping skill: `repo-hygiene` (branch, tag, rubric, and leftover audit; deletes only what the user names)
- one conformance skill: `conformance-audit` (judges the history against the procedure from an adoption baseline; read-only, exits non-zero, runs in CI)
- two layers of local guard: the git `pre-push` hook `github-sync` installs (all CLIs) and the Claude Code plugin's PreToolUse hook (blocks the `--no-verify` bypass). Both allow exactly two ways onto `main`: `develop:main` and `hotfix/<slug>:main`
- grading that starts before the release: `develop-task-flow` records a `Release-Grade` trailer on each squash commit, and `github-release` takes the highest one in the range as a floor it never lowers, alongside the advisory floor computed from the rubric's `## Interface Paths` table
- distribution: the plugin marketplace for Claude Code (`jig@jig`, namespaced by the host as `/jig:<skill>`), `jig-` prefixed skill files for Codex and Antigravity

There is **only one merge flow**: a local `git merge --squash` and a direct push to `develop`, no pull requests. A team flow is deferred as candidate C below.

## Direction Candidates (deferred, trigger-conditional)

| Candidate | What it is | Trigger to start |
|---|---|---|
| **A. More procedures** | ~~`hotfix-flow`~~ and ~~`repo-hygiene`~~ shipped; see the design record below for the two that were dropped | Closed. A further procedure needs its own candidate and its own trigger |
| **B. Conformance checking** | ~~Shipped as `conformance-audit`~~: a read-only check script plus skill that judges commit subjects, `Release-Grade` coverage, tag format and placement, and the `main`/`develop` invariant from an adoption baseline. Exit codes are the CI contract, which covers the CI-audit part of C | Started and shipped. What remains is watching whether the checks match real violations, and adding one only when a violation the audit missed appears |
| **C. A channel for teams** | Onboarding (one one-liner syncs the team's rules), per-member drift watching, CI audits, per-organization flow parameters such as approval counts. Includes restoring the PR-based merge flow (`team-pr`) — see the design record below | When real team users appear. If B runs in CI, half of this is already solved |
| **D. engine/content split (registry)** | Separate the installer, manifest, and lifecycle (engine) from the skill content, so another organization can distribute its own procedures on the jig engine. The `REPO_RAW_URL` override is already half of it — what remains is removing hardcoded values and scaffolding a procedure repository | When outside demand shows up: forks, issues, requests to distribute procedures |
| **E. Native hooks for Codex and Antigravity** | Offer the git pre-push guard as those CLIs' native PreToolUse hooks too (Codex `hooks.json` is experimental and off by default; Antigravity requires editing a user-owned settings file) | When those hooks reach GA, and a real case appears that a git hook cannot block |

## Design Record: issue-triage and dependency-update (dropped)

Both were listed under candidate A and are not being built. The reasons are kept so they are not proposed again.

**`issue-triage`** does not converge repository state, which is the line this project draws against a plain skill marketplace. Classifying issues is ordinary agent work that `gh issue list` already serves, and `github-sync` deliberately syncs no labels — a project that decided against labels should not ship a label workflow. At the size of a personal side project the triage itself is a few minutes of reading.

**`dependency-update`** is what the host already provides. Dependabot and Renovate do it for free, with the language-specific knowledge jig does not have and will not acquire; jig is shell and Markdown. The only thing left to add would be routing a bump through `develop-task-flow`, which is a thin wrapper over a skill that already exists. Building it would repeat the mistake recorded directly below.

## Design Record: Skill Ownership Markers (removed)

Before v0.2.0 the distributed payload carried a `<!-- jig:owned skill=<name> -->` marker. The installer skipped files without it, used the version stamp as an ownership ledger to take over from older versions, and reported files dropped from a selection as orphans. All of it was removed when the plugin namespace (Claude Code) and the `jig-` prefix (Codex, Antigravity) replaced it. It stays here as a case of the principle: do not reimplement what the host already provides.

## Design Record: the team-pr Flow (removed, to restore with C)

A PR-based team flow that was once implemented. With no real team users it was pure maintenance cost, so it was removed; only the design needed to restore it is kept here. The original files are in git history.

**The flow profile mechanism** (fully removed in v0.2.0, including the `--flow` option and the stamp's `flow=` field)

- The installer took `--flow <flow>` (`JIG_FLOW`), checked it against the supported-flow list in column 2 of `manifest.tsv`, and recorded the selection in the version stamp as `flow=<flow>`.
- Skill sources lived as `skills/<skill>/SKILL.md` (default) and `skills/<skill>/SKILL.<flow>.md` (variant); the variant shipped when present, otherwise the default. The installer fell back to the default when a variant payload 404'd.
- The Claude Code plugin was built once per flow (`jig`, `jig-team-pr`). Inside a plugin payload the variant had to be resolved down to `SKILL.md`.
- `jig-doctor` judged drift by `cmp` against the payload for the stamped flow, and checked a different branch protection expectation per flow.

**Where team-pr differed from solo-cli**

- `develop-task-flow`: instead of a local squash merge, push the branch, open a PR against `develop`, and `gh pr merge --squash` once checks pass. The PR body was `## Summary` (bullets for the release notes) / `## Details` / `## Tests`. Direct pushes to `develop` were forbidden. When a merge was blocked, the PR stayed open and the blocking reason was reported.
- `github-sync`: `required_pull_request_reviews` on `develop` (the approval count was team policy, `0` allowed), while `main` allowed direct pushes for the release fast-forward. Force pushes and deletion were blocked on both.
- `github-release`: no difference. Releases are CLI-driven in both flows (`develop:main` fast-forward, tag, `gh release create`).

**Before restoring it**

- Restoring it splits the skill sources per flow and doubles the maintenance. Look first at parameterizing one procedure, the way candidate C's "per-organization flow parameters" would.
- `validate-dist.sh` has guards against flow variants and the `team-pr` string. They have to be lifted at the same time.

## Next

- Apply it for real on existing side projects: install or re-run the update, converge with `github-sync`, diagnose with `jig-doctor`, clear the debris with `repo-hygiene`, and collect the friction
- Run `conformance-audit` on each of them and check its findings against what the repository is really doing: a check that fires on a repository behaving correctly is a defect in the audit, not in the repository
- A and B are closed. C, D, and E stay trigger-conditional
