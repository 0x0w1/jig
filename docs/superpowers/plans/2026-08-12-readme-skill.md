# `readme` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a SPAI-distributed `readme` skill that creates or updates a project `README.md` from verified repository state, shipped to all three CLIs.

**Architecture:** One new skill source at `skills/readme/SKILL.md`, registered in `manifest.tsv` and picked up by the existing manifest-driven build (`scripts/build-dist.sh` → `dist/`). The validator (`scripts/validate-dist.sh`) hard-fails on unknown skills, so it gains a `readme` title case. Repo-scoped copies mirror the shipped payload (`.agents/skills/spai-readme/`, `.claude/skills/readme/`). Docs that enumerate skills are updated. `install.sh` needs no change — verified during planning: it selects skills from `dist/manifest.tsv` (`load_manifest`, `manifest_default_skills`) with no hardcoded skill list. Spec: `docs/superpowers/specs/2026-08-12-readme-skill-design.md`.

**Tech Stack:** POSIX sh build scripts, tab-separated `manifest.tsv`, Markdown skill files. No test framework — verification is `sh scripts/build-dist.sh` + `sh scripts/validate-dist.sh` + `grep`/`cmp` assertions.

## Global Constraints

- Work happens on branch `feature/readme-skill` (already exists, tracks `origin/develop`); finish with `git merge --squash` into `develop` and a single `feat:` commit, then push `develop`. No PRs, no force push.
- `manifest.tsv` columns are TAB-separated: `<skill>\t<flows>\t<default>`. The new row is exactly `readme	solo-cli	yes`.
- Skill body language is English (matches the five existing skills); user-facing docs (`README.md`, `docs/*.md`) are Korean.
- Keep docs/skill examples generic: placeholders like `your-account`, no local machine paths.
- `dist/` is generated and committed; never hand-edit `dist/` files — always regenerate via `sh scripts/build-dist.sh`.
- The H1 title of the new skill is `# README` and must match the `skill_title` case added to `scripts/validate-dist.sh`, or validation fails.
- `.agents/skills/spai-readme/SKILL.md` must be byte-identical to `dist/codex/.agents/skills/spai-readme/SKILL.md` (frontmatter `name: spai-readme`). `.claude/skills/readme/SKILL.md` must be byte-identical to `skills/readme/SKILL.md`.

---

### Task 1: Skill source + build/validate integration

**Files:**
- Modify: `manifest.tsv` (append row)
- Modify: `scripts/build-dist.sh` (`skill_summary()` case block, around line 17-26)
- Modify: `scripts/validate-dist.sh` (`skill_title()` case block, around line 21-30)
- Create: `skills/readme/SKILL.md`
- Regenerate: `dist/` (via build script)

**Interfaces:**
- Produces: skill id `readme` in the manifest; `dist/codex/.agents/skills/spai-readme/SKILL.md`, `dist/antigravity/.agents/skills/spai-readme/SKILL.md`, `dist/claude-code-plugin/spai/skills/readme/SKILL.md`. Task 2 copies from these outputs.

- [ ] **Step 1: Register the skill before it exists (failing state)**

Append to `manifest.tsv` (TAB-separated, after the `spai-doctor` row):

```text
readme	solo-cli	yes
```

In `scripts/build-dist.sh`, inside `skill_summary()`, add before the `*)` line:

```sh
    readme) printf '%s' "write or update the project README from the repository state; drafts one when missing, fixes drift when present." ;;
```

In `scripts/validate-dist.sh`, inside `skill_title()`, add before the `*)` line:

```sh
    readme) printf '%s\n' "# README" ;;
```

- [ ] **Step 2: Run the build to verify it fails**

Run: `sh scripts/build-dist.sh`
Expected: FAIL — `awk` (or `cp`) cannot open `skills/readme/SKILL.md`, non-zero exit. This proves the manifest row drives the build.

- [ ] **Step 3: Write the skill source**

Create `skills/readme/SKILL.md` with exactly this content:

````markdown
---
name: readme
description: "Use when writing or updating a project README.md: scan the repository to classify the project type (CLI tool, library, service or app), draft a new README when none exists, or compare the existing README's claims (commands, options, paths, links) against the repository and fix the drift. Writes only verified facts; keeps the existing README language and defaults to Korean for new files."
---

# README

Use this skill to create or update the repository's `README.md` from the actual repository state.

## Procedure

1. Scan the repository:
   - Manifest and build files: `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Makefile`, lock files.
   - Entry points, CLI argument definitions, scripts, and service configs (`Dockerfile`, `docker-compose*.yml`).
   - Existing documentation under `docs/` and usage examples in the code.
2. Classify the project type: **CLI tool**, **library**, **service/app**, or **other**. The type selects the section layout below.
3. Branch on the current state:
   - No `README.md` → **create path**: draft the README with the section layout below.
   - `README.md` exists → **update path**: check every verifiable claim in the README — commands, options, file paths, links, feature statements — against the repository. Collect mismatches into a drift list, report the list, then apply the fixes. Leave sections that are still accurate untouched.
4. Apply the accuracy rules to every line written.
5. Merge the change:
   - When the repository has the `develop-task-flow` skill (or the installed `spai-develop-task-flow`), follow it: a `chore/<slug>` branch, a squash merge with a `docs:` commit, then push `develop`.
   - Otherwise propose a normal commit on the current branch.

## Section Layout

Required sections, in order:

1. Title plus a one-line description.
2. Introduction: what the project does and why it exists.
3. Installation.
4. Usage.

Additions by project type:

- CLI tool: a command and option table.
- Library: an API summary with example code.
- Service/app: how to run it (dev and prod) and the required environment variables.

Optional: documentation links, license.

## Accuracy Rules

- Write only install and run commands verified against the repository: a script, manifest, or lock file must show them.
- Verify that every linked file path exists.
- Do not describe features, badges, or integrations the repository does not contain.
- When a claim cannot be verified, leave it out and report it instead.

## Language Rules

- An existing README keeps its language.
- A new README is written in Korean with technical terms in backticks.
- An explicit language request from the user overrides both.

## Report

- Project type and the path taken (create or update).
- On the update path: the drift list and what was fixed.
- Claims that could not be verified and were left out.
````

- [ ] **Step 4: Rebuild and validate to verify green**

Run: `sh scripts/build-dist.sh && sh scripts/validate-dist.sh`
Expected: build lists `dist/codex/.agents/skills/spai-readme/SKILL.md`, `dist/antigravity/.agents/skills/spai-readme/SKILL.md`, `dist/claude-code-plugin/spai/skills/readme/SKILL.md`; validator prints `dist validation ok`.

Then run: `grep -c 'name: spai-readme' dist/codex/.agents/skills/spai-readme/SKILL.md`
Expected: `1` (frontmatter name rewritten to the prefixed form).

Then run: `grep -F -- '- `spai-readme`:' dist/codex/AGENTS.md dist/antigravity/GEMINI.md`
Expected: one hit per file (managed-block skill list includes the new skill).

- [ ] **Step 5: Commit**

```bash
git add manifest.tsv scripts/build-dist.sh scripts/validate-dist.sh skills/readme/SKILL.md dist
git commit -m "feat: add readme skill source and build integration"
```

---

### Task 2: Repo-scoped skill copies

**Files:**
- Create: `.agents/skills/spai-readme/SKILL.md`
- Create: `.claude/skills/readme/SKILL.md`

**Interfaces:**
- Consumes: Task 1 outputs `dist/codex/.agents/skills/spai-readme/SKILL.md` and `skills/readme/SKILL.md`.

- [ ] **Step 1: Copy the payloads**

```bash
mkdir -p .agents/skills/spai-readme .claude/skills/readme
cp dist/codex/.agents/skills/spai-readme/SKILL.md .agents/skills/spai-readme/SKILL.md
cp skills/readme/SKILL.md .claude/skills/readme/SKILL.md
```

- [ ] **Step 2: Verify the copies match their sources**

Run: `cmp .agents/skills/spai-readme/SKILL.md dist/codex/.agents/skills/spai-readme/SKILL.md && cmp .claude/skills/readme/SKILL.md skills/readme/SKILL.md && echo copies-ok`
Expected: `copies-ok`

- [ ] **Step 3: Commit**

```bash
git add .agents/skills/spai-readme .claude/skills/readme
git commit -m "feat: sync readme skill copies for codex and claude code"
```

---

### Task 3: Documentation updates

**Files:**
- Modify: `README.md` (제공 스킬 표, around line 20-26)
- Modify: `docs/roadmap.md` (현재 제공, around line 16-19)
- Modify: `docs/installation.md` (three spots: 활용 list ~line 37-41, project scope tree ~line 81-85, 제거 command ~line 114-115)
- Modify: `CLAUDE.md` (repo-scoped skill list, lines 5-7)
- Modify: `AGENTS.md` (repo-scoped skill list, lines 5-7)

**Interfaces:**
- Consumes: skill id `readme` / `spai-readme` from Task 1. No later task depends on this one.

- [ ] **Step 1: README.md — add a row to the 제공 스킬 표**

After the `spai-doctor` row:

```markdown
| `readme` | 프로젝트 타입 판정 후 `README.md` 생성, 기존 README는 코드와 대조해 드리프트 수정 |
```

- [ ] **Step 2: docs/roadmap.md — extend 현재 제공**

After the `- 수명주기 스킬 2종: ...` line, add:

```markdown
- 문서 스킬 1종: `readme` (README 생성·갱신)
```

- [ ] **Step 3: docs/installation.md — three additions**

In the 활용 code block, after `/spai:spai-doctor` add a line:

```text
/spai:readme
```

In the project scope tree, after `  spai-doctor/SKILL.md` add a line:

```text
  spai-readme/SKILL.md
```

Replace the 제거 command block content:

```bash
rm -rf .agents/skills/spai-github-sync .agents/skills/spai-github-release \
  .agents/skills/spai-develop-task-flow .agents/skills/spai-update .agents/skills/spai-doctor \
  .agents/skills/spai-readme
```

- [ ] **Step 4: CLAUDE.md and AGENTS.md — add the skill to the repo-scoped lists**

`CLAUDE.md`, after the `develop-task-flow` line in "Use these repo-scoped Claude Code skills":

```markdown
- README writing/updating: `readme` from `.claude/skills/readme/SKILL.md`.
```

`AGENTS.md`, after the `spai-develop-task-flow` line in "Use these repo-scoped Codex skills":

```markdown
- README writing/updating: `spai-readme` from `.agents/skills/spai-readme/SKILL.md`.
```

- [ ] **Step 5: Verify enumeration consistency**

Run: `grep -l 'readme' README.md docs/roadmap.md docs/installation.md CLAUDE.md AGENTS.md | wc -l`
Expected: `5`

Run: `sh scripts/validate-dist.sh`
Expected: `dist validation ok` (docs edits must not break anything).

- [ ] **Step 6: Commit**

```bash
git add README.md docs/roadmap.md docs/installation.md CLAUDE.md AGENTS.md
git commit -m "docs: list the readme skill in user-facing docs"
```

---

### Task 4: Dry-run of the update path (spec verification item)

**Files:**
- Read-only against this repository; no planned edits.

**Interfaces:**
- Consumes: the procedure text of `skills/readme/SKILL.md` from Task 1.

- [ ] **Step 1: Execute the skill procedure manually against this repository**

Follow `skills/readme/SKILL.md` steps 1-3 with this repo as the target: scan (`manifest.tsv`, `install.sh`, `scripts/`, `docs/`), classify (expected: CLI tool — installer plus CLI-invoked skills), and run the update path against the existing `README.md`: verify its commands (`/plugin marketplace add 0x0w1/spai`, `curl ... install.sh` one-liners), file links (`docs/installation.md`, `docs/versioning.md`, `docs/github-repository-settings.md`, `docs/roadmap.md`), and the skill table (now six rows).

- [ ] **Step 2: Report the outcome**

Expected: empty or near-empty drift list (README was updated in Task 3). Report any drift found to the user instead of auto-fixing it in this task; a real fix would be its own `docs:` change. This step passes when the procedure was executable as written — every instruction had a concrete answer against a real repository.

---

### Task 5: Squash merge into develop and push

**Files:**
- Branch operation only.

**Interfaces:**
- Consumes: all commits on `feature/readme-skill` (spec commit `6b0e525` plus Tasks 1-3).

- [ ] **Step 1: Verify the branch is clean and validation passes**

Run: `git status --short && sh scripts/validate-dist.sh`
Expected: empty status, `dist validation ok`.

- [ ] **Step 2: Squash merge**

```bash
git switch develop
git pull --ff-only origin develop
git merge --squash feature/readme-skill
git commit -m "feat: add readme skill

- 프로젝트 \`README.md\`를 작성·갱신하는 \`readme\` 스킬을 추가했습니다. 저장소를 스캔해 프로젝트 타입(CLI 도구/라이브러리/서비스·앱)을 판정하고, README가 없으면 타입별 섹션 구성으로 초안을 만들고, 있으면 README의 주장(명령·옵션·경로·링크)을 코드와 대조해 드리프트를 보고한 뒤 수정합니다.
- 검증된 사실만 쓰는 정확성 규칙과 언어 규칙(기존 언어 유지, 신규는 한국어 기본)을 절차에 포함했습니다.
- 세 CLI 모두에 배포됩니다: Claude Code \`/spai:readme\`, Codex/Antigravity \`spai-readme\`.
- \`manifest.tsv\`, \`build-dist.sh\`, \`validate-dist.sh\`, 설치 문서에 새 스킬을 등록했습니다."
```

- [ ] **Step 3: Push develop**

Run: `git push origin develop`
Expected: fast-forward push accepted.

- [ ] **Step 4: Verify**

Run: `git log origin/develop --oneline -1 && git log v0.3.1..origin/develop --oneline | wc -l`
Expected: the squash commit on top; count `1`.

---

## After the plan

The user asked for a release once the skill is complete. Run the `github-release` skill next; the grade is `minor` (new capability → `v0.4.0`), not the originally requested `patch` — already reported to the user, who chose to finish this work first.
