---
name: jig-hotfix-flow
description: Use when a released defect on main must ship before the work already sitting on develop. Branches from main, lands one squashed commit on main through the guard-allowed hotfix push, tags and publishes, then merges main back into develop so the next release still fast-forwards.
---

# Hotfix Flow

Use this repository skill only when a defect already released on `main` must be fixed **before** the work waiting on `develop` is ready to ship.

Every other fix is an ordinary task. Use `develop-task-flow` and let the fix ride the next release.

## When This Applies

All three must hold. If any one fails, this is not a hotfix.

1. The defect is reachable from `main`, so people already have it.
2. Waiting for the next `develop` release is not acceptable.
3. `develop` holds work that must **not** ship yet. When `develop` has nothing unreleased, there is no hotfix: fix it with `develop-task-flow` and release normally.

## Why the Model Needs a Separate Flow

`main` normally only moves by the release fast-forward `git push origin develop:main`, and both jig guards block anything else. A hotfix is the one operation that puts a commit on `main` that `develop` does not have.

That divergence is the whole risk. Once `main` holds a commit `develop` lacks, `git push origin develop:main` stops fast-forwarding and `github-release` refuses to run — correctly, because the alternative is a force push.

**So the back-merge is part of this procedure, not a follow-up.** A hotfix that lands on `main` without returning to `develop` leaves the repository unable to release.

## Landing on develop: Merge, Never Cherry-Pick

Bring the hotfix back with `git merge main` into `develop`.

Do not cherry-pick it. A cherry-pick copies the change under a new SHA, so `main` stays outside `develop`'s history and every later `develop:main` push fails the fast-forward check. The merge is what makes `main` an ancestor of `develop` again.

The merge commit itself never reaches the release notes: `github-release` reads `git log <previous>..<version> --no-merges`. The hotfix commit is already behind the hotfix tag, so it is not repeated in the next release either.

## Release Grade

Grade the hotfix against the repository's version rubric, resolved in this order:

1. `JIG_VERSION_RUBRIC` environment variable.
2. `git config --local --get jig.versionRubric` (repository override).
3. `.jig/versioning.md` (the convention).

Apply its `## Decision Order` to this fix alone, stopping at the first match, then its `## Hard Rules`. Use `git diff --name-only origin/main...HEAD` as evidence, and read the floor from `## Interface Paths` when the rubric has that table. Record the verdict as a trailer on the squash commit body:

```text
Release-Grade: patch
```

`version-rubric` owns the rubric file. Never edit it from here.

## Version

- Compute from the latest `vX.Y.Z` tag reachable from `origin/main` (`git describe --tags --abbrev=0 origin/main`), using the graded bump and the rubric's `## Version Format` when it has one.
- A hotfix is usually `patch`. It is not automatically `patch`: grade it, and if the fix changes behavior silently the rubric says so.
- The tag is created on the commit that landed on `main`, not on a `develop` commit.

## Safety Rules

- Do not force push.
- Do not bypass git hooks: never pass `--no-verify` to any push.
- Push `main` only as `git push origin hotfix/<slug>:main`, and only when it fast-forwards. If it is rejected, stop and report; someone else moved `main`.
- Do not start a hotfix from `develop`. The branch point is `origin/main`, or the fix carries unreleased work with it.
- Do not include anything beyond the defect. A hotfix that also carries a refactor is an ordinary task.
- Do not leave `main` ahead of `develop`. The back-merge runs in the same session, before the report.
- Do not resolve a failed `develop:main` fast-forward by force-pushing; that is the state this skill exists to prevent.
- Do not delete branches without explicit user confirmation.
- Do not edit the rubric file.
- Preserve unrelated user changes.

## Procedure

1. Inspect and confirm the three conditions in When This Applies:
   - `git status --short --branch`
   - `git fetch origin --prune --tags`
   - `git log --oneline origin/main..origin/develop` — unreleased work that must not ship
2. Create the branch from the released state: `git checkout -b hotfix/<slug> origin/main`.
3. Implement only the fix.
4. Run the most relevant focused test, then the repository's broader validation when practical. Report any gap.
5. Reduce the branch to one commit on top of `origin/main`:
   - `git reset --soft origin/main`
   - commit once with a `fix:` subject, user-facing body bullets, and the `Release-Grade` trailer
6. Land it: `git push origin hotfix/<slug>:main`. This must fast-forward.
7. Tag the commit that is now `main` and publish:
   - `git tag <version> $(git rev-parse hotfix/<slug>)`
   - `git push origin <version>`
   - `gh release create <version> --title "<version> 🌈" --notes-file <draft>`
   - Resolve the GitHub profile the way `github-release` does before any `gh` command.
8. **Return to develop in the same session:**
   - `git checkout develop`
   - `git pull --ff-only origin develop`
   - `git merge main` — resolve conflicts here, never by dropping the fix
   - `git push origin develop`
9. Verify the invariant is restored: `git merge-base --is-ancestor origin/main origin/develop` must succeed. Until it does, the next release cannot run.
10. Report.

## Release Notes

Follow the `github-release` note format: `## Changes` with the section its commit prefix selects (`fix:` → `### 🐛 Fixes`), then a `### Summary` in the language the repository already uses.

Say plainly that this release came from `main` and that `develop` work is not included. Someone reading two adjacent tags should not have to guess why the second one carries less.

## Final Report

- Branch, and the `origin/main` commit it started from
- Files changed and tests run
- Graded bump, the rubric question that decided it, and the recorded `Release-Grade`
- Version tagged and the release URL
- Back-merge result and the `merge-base --is-ancestor` verification
- Unreleased `develop` work that was deliberately left out
- Commands that could not run and why
