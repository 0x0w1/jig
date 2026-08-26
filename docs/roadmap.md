# SPAI Roadmap

[한국어](roadmap.ko.md)

> A record of direction ideation. Candidates are kept together with their trigger conditions, whether or not they are being worked on.

## Identity

Early SPAI is **a harness setup tool for the CLI agents used on personal side projects.** The targets are Claude Code, Codex, and Antigravity CLI.

What separates it from a plain skill marketplace:

1. **It converges repository state too** — not only session skills, but the branch model, branch protection, and release discipline, managed by `github-sync` (convergence) and `spai-doctor` (diagnosis)
2. **Cross-agent consistency plus lifecycle** — one procedure source (`skills/`) rendered into several CLIs, with the version stamp, `spai-update`, and `spai-doctor` managing what happens after the install

## What Ships Today

- installer: installs pinned to the latest release tag, `--version` rollback, `--skills` selective install (the `manifest.tsv` catalog; codex and antigravity only)
- three workflow skills: `develop-task-flow`, `github-release`, `github-sync`
- two lifecycle skills: `spai-update`, `spai-doctor`
- one onboarding skill: `project-setup` (selects and verifies the per-repository GitHub profile after install)
- three documentation skills: `readme` (write or update a README), `version-rubric` (settle the version rubric and ship the per-type catalog), `rubric-scan` (scan the repository and recommend one)
- two layers of local guard: the git `pre-push` hook `github-sync` installs (all CLIs) and the Claude Code plugin's PreToolUse hook (blocks the `--no-verify` bypass)
- distribution: the plugin marketplace for Claude Code (`spai@spai`, namespaced by the host as `/spai:<skill>`), `spai-` prefixed skill files for Codex and Antigravity

There is **only one merge flow**: a local `git merge --squash` and a direct push to `develop`, no pull requests. A team flow is deferred as candidate C below.

## Direction Candidates (deferred, trigger-conditional)

| Candidate | What it is | Trigger to start |
|---|---|---|
| **A. More procedures** | More procedures in the same domain: `hotfix-flow` (urgent fix on main, reflected back into develop), `issue-triage`, `dependency-update`, `repo-hygiene` (an extended doctor audit) | When real use shows a repeated behavior, one at a time. No building ahead — skills stay minimal |
| **B. Conformance checking** | Machine verification that the agent actually followed the procedure: an after-the-fact audit that commits, tags, and notes match the rules. Designed as a check script that also runs in CI, it covers the CI-audit part of C | When violations accumulate in real use |
| **C. A channel for teams** | Onboarding (one one-liner syncs the team's rules), per-member drift watching, CI audits, per-organization flow parameters such as approval counts. Includes restoring the PR-based merge flow (`team-pr`) — see the design record below | When real team users appear. If B runs in CI, half of this is already solved |
| **D. engine/content split (registry)** | Separate the installer, manifest, and lifecycle (engine) from the skill content, so another organization can distribute its own procedures on the SPAI engine. The `REPO_RAW_URL` override is already half of it — what remains is removing hardcoded values and scaffolding a procedure repository | When outside demand shows up: forks, issues, requests to distribute procedures |
| **E. Native hooks for Codex and Antigravity** | Offer the git pre-push guard as those CLIs' native PreToolUse hooks too (Codex `hooks.json` is experimental and off by default; Antigravity requires editing a user-owned settings file) | When those hooks reach GA, and a real case appears that a git hook cannot block |

## Design Record: Skill Ownership Markers (removed)

Before v0.2.0 the distributed payload carried a `<!-- spai:owned skill=<name> -->` marker. The installer skipped files without it, used the version stamp as an ownership ledger to take over from older versions, and reported files dropped from a selection as orphans. All of it was removed when the plugin namespace (Claude Code) and the `spai-` prefix (Codex, Antigravity) replaced it. It stays here as a case of the principle: do not reimplement what the host already provides.

## Design Record: the team-pr Flow (removed, to restore with C)

A PR-based team flow that was once implemented. With no real team users it was pure maintenance cost, so it was removed; only the design needed to restore it is kept here. The original files are in git history.

**The flow profile mechanism** (fully removed in v0.2.0, including the `--flow` option and the stamp's `flow=` field)

- The installer took `--flow <flow>` (`SPAI_FLOW`), checked it against the supported-flow list in column 2 of `manifest.tsv`, and recorded the selection in the version stamp as `flow=<flow>`.
- Skill sources lived as `skills/<skill>/SKILL.md` (default) and `skills/<skill>/SKILL.<flow>.md` (variant); the variant shipped when present, otherwise the default. The installer fell back to the default when a variant payload 404'd.
- The Claude Code plugin was built once per flow (`spai`, `spai-team-pr`). Inside a plugin payload the variant had to be resolved down to `SKILL.md`.
- `spai-doctor` judged drift by `cmp` against the payload for the stamped flow, and checked a different branch protection expectation per flow.

**Where team-pr differed from solo-cli**

- `develop-task-flow`: instead of a local squash merge, push the branch, open a PR against `develop`, and `gh pr merge --squash` once checks pass. The PR body was `## Summary` (bullets for the release notes) / `## Details` / `## Tests`. Direct pushes to `develop` were forbidden. When a merge was blocked, the PR stayed open and the blocking reason was reported.
- `github-sync`: `required_pull_request_reviews` on `develop` (the approval count was team policy, `0` allowed), while `main` allowed direct pushes for the release fast-forward. Force pushes and deletion were blocked on both.
- `github-release`: no difference. Releases are CLI-driven in both flows (`develop:main` fast-forward, tag, `gh release create`).

**Before restoring it**

- Restoring it splits the skill sources per flow and doubles the maintenance. Look first at parameterizing one procedure, the way candidate C's "per-organization flow parameters" would.
- `validate-dist.sh` has guards against flow variants and the `team-pr` string. They have to be lifted at the same time.

## Next

- Apply it for real on existing side projects: install or re-run the update, converge with `github-sync`, diagnose with `spai-doctor`, and collect the friction
- The repeated behaviors and violations that surface there are the raw material for A and B
