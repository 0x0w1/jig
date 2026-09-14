---
name: jig-develop-task-flow
description: "Use for ordinary implementation tasks in a repository that has adopted the jig develop/main model: start from develop, create a feature/fix/chore branch, complete changes and tests, squash-merge back into develop locally, and push develop. No pull requests. Execution scope comes from the current request and explicitly approved repository policy; installation or branch names alone grant no permission."
---

# Develop Task Flow

Use this repository skill for normal development work requested by the user.

## Applies When

**Installation is not adoption.** jig can be installed user-global — a Claude Code user-scope plugin, a Codex plugin — and is then present in every repository on the machine, including ones that never took up this branch model. Being loaded here says nothing about how this repository works.

Adoption comes from repository instructions or an earlier explicit user decision to use jig's `develop/main` flow. Installing or loading jig, and branch names alone, do not establish that decision. Read the relevant repository policy; do not introduce a new configuration flag.

Check the branch prerequisites separately, using local and remote-tracking refs for both `main` and `develop`:

```bash
git show-ref --verify --quiet refs/heads/main || git show-ref --verify --quiet refs/remotes/origin/main
git show-ref --verify --quiet refs/heads/develop || git show-ref --verify --quiet refs/remotes/origin/develop
```

- **Adopted, prerequisites present** → use the branch model within Execution Scope.
- **Not adopted, unclear, or prerequisites missing** → complete authorized local work and verification under the repository's own workflow. Do not create `develop`, infer approval to push, or replace that workflow. If committing was requested, follow its existing commit policy. Report any prerequisite that blocks an authorized landing; `jig-setup` or `github-sync` can establish the model when adoption/setup is requested.

## Execution Scope

Distinguish four stages; permission for one does not imply later stages:

| Stage | What it does |
|---|---|
| 1. Edit and verify | requested file edits and relevant checks |
| 2. Commit | record task changes in Git |
| 3. Land | task branch, squash merge, push `develop` |
| 4. Release | promote, tag, publish via `github-release` |

Set the ceiling from the user's current request and repository policy they have explicitly approved:

1. **Current limits win.** Local only, no commit, no merge, no push, or leave for review limits this task even under a standing landing policy. A review/diagnosis request authorizes inspection and reporting; edit files only when fixes are also requested. Implement/fix/update authorizes the work, but those verbs alone do not authorize committing or pushing.
2. **Reuse standing approval.** If repository instructions already authorize committing and landing ordinary tasks, complete those stages without asking again unless the current request limits them. Adopting branch names alone is not that authorization. With no approval for a later stage, finish the authorized work and report it; do not make an optional commit/push question block local implementation.
3. **Release is separate.** Stage 4 always needs an explicit release request and belongs to `github-release`.

**Being called by another skill does not widen scope.** `readme`, `version-rubric`, and other callers pass the original request and its ceiling. Their ability to delegate a commit grants no additional permission. Decide reversible implementation details within the approved change; ask only for unresolved user decisions needed to proceed.

## Branch Model

- Start from `origin/develop`.
- Create one task branch:
  - `feature/<slug>` for user-visible features or enhancements.
  - `fix/<slug>` for bug, regression, or security fixes.
  - `chore/<slug>` for tooling, dependencies, refactors, docs, or automation setup.
- When landing is authorized, finish the task by squash-merging the branch into `develop` locally and pushing `develop`. There are no pull requests.
- Ordinary code, config, documentation, generated `dist`, workflow, and installer changes must follow this flow before any release can include them.
- A release promotes `develop` to `main` with a fast-forward push; it is not a task. Use `github-release` for releases.

## Commit Message Rules

The squash commit on `develop` is the release-note source. Every squash commit must follow this format:

- Subject: `<type>: <concise user-facing summary>` with `<type>` one of `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`.
- Release note sections derive from the prefix: `feat:` renders under `🚀 Enhancements`, `fix:` under `🐛 Fixes`, `chore:` under `🧰 Chores`, and any other prefix becomes its own section named after it (`docs:` → `📚 Documentation`). Pick the prefix that describes the change, not the section you want.
- Body: bullet items describing the change from the user's perspective, release-note ready. Write them in the language the repository already uses for its commit bodies, defaulting to English; match the existing history rather than switching it.
- In body bullets, wrap useful technical terms in backticks, such as file paths, config keys, branch names, workflow names, command names, and env vars.

## Release Grade

The squash commit records the grade this task earns. Decide it here rather than at release time: at merge the diff, the tests, and the reasoning are still in hand, while a release has to reconstruct all of it from commit text.

Grade against the repository's own rubric, not a fixed prefix mapping — a prefix names the kind of change, not what it costs. Resolve the rubric path in this order:

1. `JIG_VERSION_RUBRIC` environment variable.
2. `git config --local --get jig.versionRubric`.
3. `.jig/versioning.md`.

Apply that rubric's `## Decision Order` to this task alone, asking its questions in order and stopping at the first match, then apply its `## Hard Rules`. Use the changed paths as evidence, not only the commit text:

```bash
git diff --name-only origin/develop...HEAD
```

Check that list against whatever the rubric names as the project's public interface. A path the rubric calls internal does not raise the grade on its own; a path it calls public sets the floor at the grade the rubric assigns it.

When the rubric has an `## Interface Paths` table, read the floor from it instead of judging the paths by eye: each changed path takes the floor of the first row it matches, and the task floor is the highest of those. That floor is advisory — it says what the task touched, never how — so grading below it is allowed when the change under a public path does not reach that grade. Say so in the report when it happens.

Record the verdict as a trailer on the last line of the squash commit body:

```text
Release-Grade: minor
```

- One trailer per squash commit. The value is `patch`, `minor`, or `major`, lowercase, with nothing else on the line.
- The grade covers this task only. `github-release` takes the highest grade recorded across the release range as the floor, so a task never has to predict what ships alongside it.
- If no rubric resolves, omit the trailer instead of guessing. The release then grades that commit from its text, as it did before.
- The trailer is grading input, not release-note prose. Never copy it into a note bullet.

## Phase Rules

If the task is large, split it into phases:

1. Inspect repo, worktree, branch state, and available test commands, and settle the scope.
2. Create or reuse the task branch from `origin/develop`, when the scope reaches stage 3.
3. Implement the requested change.
4. Run focused tests and required broader checks; repeat or expand only for new evidence.
5. Commit on the task branch, squash-merge into `develop`, push `develop` — each step only as far as the scope reaches.
6. Report results, the scope taken, and any remaining action.

## Documentation Rules

- If a change affects installation behavior, user-facing workflows, supported targets, repository policy, CLI output, or public project usage, update `README.md` in the same task.
- If the change is broad or would make `README.md` too dense, create or update a focused Markdown file under top-level `docs/` and add a link near the top of `README.md`.
- If top-level `docs/` already exists, reuse it instead of creating another documentation directory.
- This repository is itself managed by the jig setup skills, and its documentation, skills, and installer are distributed publicly. Every example must stay generic: use placeholders such as `your-account`, `your@email.com`, and `/absolute/path/to/<name>`. Never include local machine paths, personal identifiers, or examples taken from local or other projects.
- During validation, check that the README/docs update explains the new behavior clearly.

## Safety Rules

- Do not force push.
- Do not bypass git hooks: never pass `--no-verify` to `git push`.
- Do not delete branches without explicit user confirmation; merged task branches may remain.
- Do not push directly to `main`; `main` only updates through `github-release`.
- Do not modify or revert unrelated user changes.
- Read `git status --short` and the relevant diff before editing. Normal task-scoped edits, including edits to an already modified file that preserve existing user work, need no fresh approval. Explicit confirmation is needed only when a replacement would discard unrelated or otherwise unapproved user content; a dirty file alone is not a reason to ask. Patch around existing changes and never include unrelated edits in a commit.
- Decide reversible implementation details yourself — naming, file placement, refactor shape, which helper to reuse. Ask only what the user alone can settle: scope, external behavior, irreversible operations, and anything the Safety Rules require confirmation for. A question the repository already answers is not a question.
- Do not merge into `develop` if tests fail or the squash commit would include changes outside the current task.
- Do not record a `Release-Grade` the resolved rubric does not support, and omit the trailer entirely when no rubric resolves.
- Do not use this skill for release execution; use `github-release`.
- Stop at the authorized ceiling; after an authorized landing, stop without releasing unless a release was explicitly requested.

## Procedure

1. Inspect, and settle Applies When and Execution Scope from what you find:
   - `git status --short --branch`
   - Fetch `origin` when needed for an authorized landing; a local review does not require a fetch or prune.
   - `git branch --list --all`
   - available test scripts or project docs
2. Classify branch prefix:
   - `feature` for new behavior or user-visible enhancement.
   - `fix` for bug/security/regression correction.
   - `chore` for tooling, docs, refactor, config, dependency, or automation work.
3. Create a short kebab-case slug from the task.
4. Create or reuse `<prefix>/<slug>` from `origin/develop`. Skip this and every later branch step when Execution Scope caps the run below stage 3.
5. Implement the task while preserving unrelated changes.
6. Run tests:
   - Always run the most relevant focused test command if one exists.
   - Run the broad project test command when practical.
   - If no tests exist, run syntax/config validation appropriate to changed files and report the gap.
7. Apply the Documentation Rules before committing.
8. When committing is authorized, commit only task changes. At stage 2 use the branch allowed by the repository policy and request; creating or switching a branch also requires that scope. At stage 3 use the task branch.
9. Update `develop`: `git checkout develop` then `git pull --ff-only origin develop`.
10. Squash-merge: `git merge --squash <prefix>/<slug>`, then grade the task per Release Grade and commit once following the Commit Message Rules, ending the body with the `Release-Grade` trailer.
11. Push `develop` without force.
12. Leave the task branch in place; offer cleanup only as an optional next action.

Steps 8 through 11 run only as far as the settled scope allows. A run capped at stage 1 stops after step 7 and reports the working-tree changes; a run capped at stage 2 stops after step 8.

## Final Report

Keep reports short and include:

- Scope the run took: edit and verify | committed | landed on `develop`, and what decided it
- Whether the repository has adopted this flow, when that changed the scope
- Branch created or reused, or none because the run stopped earlier
- Files changed
- Tests run and result
- README/docs update status
- Squash commit subject pushed to `develop`
- Recorded `Release-Grade` and the rubric question that decided it, or why the trailer was omitted
- Commands that could not run and why
- User next actions, if any
