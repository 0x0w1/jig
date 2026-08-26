# Versioning Policy

[한국어](versioning.ko.md)

> This document is the human-readable commentary. The normative source for grading a jig release is [`.jig/versioning.md`](../.jig/versioning.md), and that is the file `github-release` reads at release time. The two must say the same thing.
>
> jig installed in another project reads *that* project's `.jig/versioning.md`. How to create or re-settle a rubric is in [version rubric](version-rubric.md).

A jig `vX.Y.Z` bump is decided by **what an installation actually pays**, not by the kind of change it was. The main consumer of the release notes is the `jig-update` skill rather than a person, so a change an agent can finish unattended and a change that needs a human decision never share a grade.

## Decision Order

Ask three questions in order and stop at the first match.

1. Does the installation need to do nothing, or does re-running the update converge it? → `patch`
2. Does something break, but either (a) `jig-update` repairs it unattended, or (b) **the failure names its own replacement at the point of failure**? → `minor`
3. Does it need a human decision, or does behavior **change quietly without failing**? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | The public interface is unchanged: internals, documentation, skill wording, `dist` regeneration. | procedure wording improved, `install.sh` bug fixed, `README` reorganized, `dist` layout changed |
| `minor` | A new capability, or a **guided break**. | new skill or target, a removed option that fails while naming its replacement, a skill directory rename `jig-update` migrates for you |
| `major` | A **human decision** is needed, or behavior **changes quietly**. | branch model changed, branch protection policy changed, user files or labels deleted, the same command returning a different result without an error |

The loosening that matters is that **a break you can fix is `minor`**. One hard rule pays for it.

> **A quiet behavior change is always `major`.**

When a failure is loud, it costs the user one error message. When it is quiet, it costs a debugging session. That guard is what makes the rest honest to loosen.

## Public Interface

The list is fixed so that what counts as a break is not re-argued every release.

**Public — breaking this is at least `minor`**

1. The curl one-liner and the post-install GitHub profile contract: `--target`, `--scope`, the optional `--github-profile`/`--github-account`, `JIG_GITHUB_PROFILE`, `jig.githubProfile`
2. Skill invocation names: `/jig:github-release`, `jig-github-release`
3. Plugin and marketplace names: `jig@jig`, `0x0w1/jig`
4. Managed block marker strings: `<!-- jig:start ... -->`, `<!-- jig:end ... -->`
5. The repository model: branch names, merge flow, protection policy

**Internal — `patch` even when it breaks**

The `dist/` layout, `scripts/*`, the wording inside skills, fields of the version stamp other than `version`, log text, and the structure of `README` and `docs`.

## Machine-Readable Migration

The `### Migration` section is not prose. It is written as two kinds of marker block, because it is input `jig-update` executes rather than a paragraph a person reads.

```md
### Migration

<!-- jig:start migration-auto -->
- `rm -f .github/workflows/drafter.yaml`
- Move `.agents/skills/github-sync/` to `.agents/skills/jig-github-sync/` when it exists
<!-- jig:end migration-auto -->

<!-- jig:start migration-manual -->
- Decide whether `develop` keeps its required status checks; jig no longer sets them.
<!-- jig:end migration-manual -->
```

| Block | Meaning | Handling |
|---|---|---|
| `migration-auto` | A mechanical step an agent finishes unattended | `jig-update` runs it |
| `migration-manual` | A step that needs human judgement | `jig-update` presents it and **does not run it without approval** |

An `auto` item must be **idempotent** and must be either a single command or an unambiguous file operation. A target that is already absent counts as done. Anything involving judgement, a choice, or an irreversible action is `manual`.

**A marker counts only when it is the entire line** (`^<!-- jig:(start|end) migration-(auto|manual) -->$`). Release notes name these markers in prose all the time, so an occurrence inside backticks or mid-sentence is text, not a marker. Counting substrings would turn those mentions into blocks. An opened block with no matching end marker is reported as a defect, and nothing is executed.

### The Version Follows From the Notes

The presence of the two blocks forces the bump. The grade is derived from the notes, not chosen by taste.

| What the notes contain | Forced bump |
|---|---|
| No Migration section | `patch` or `minor`, settled by the decision order |
| `migration-auto` only | at least `minor` |
| Any `migration-manual` | **`major`** |

`github-release` runs this check after composing the notes, and stops and reports when the grade and the requested bump disagree.

## Before 1.0

The project is on `0.x`, so a `major` grade still lands on `v0.(Y+1).0`. Grade exactly as after 1.0 and record the verdict in the release report. The point is to exercise the rule before it becomes binding.

The position it lands on changes nothing about the notes: a `migration-manual` block is still carried in full. The number moved down; the user's work did not disappear.

## Worked Examples

| Release | Grade | Why |
|---|---|---|
| `v0.2.0`, the move to a plugin | `major` | The invocation name changed from `/github-release` to `/jig:github-release` while files copied by the older version stayed behind quietly, so behavior forked. Nothing failed |
| `v0.2.1`, splitting the targets | `minor` | It breaks public item 1, but running `--target all` stops while naming the replacement command — a guided break |

Both releases actually shipped under a different grade at the time. This table shows how the current rule reads them.

## Related

- [Installation guide](installation.md)
- [GitHub repository settings](github-repository-settings.md)
