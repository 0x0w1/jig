---
name: spai-rubric-scan
description: "Use when recommending which version rubric fits this repository: scan the tracked files to classify the project type against the rubric catalog, report the top candidates with the paths that produced them, and hand the chosen draft to version-rubric. Read-only; never writes the rubric file."
---

# Rubric Scan

Use this repository skill to find out **what kind of project this repository is**, and which version rubric it should grade releases with. The scan reads the repository, scores it against the rubric catalog, and reports candidates with evidence. Writing `.spai/versioning.md` belongs to `version-rubric`; this skill never writes it.

Run it before setting a rubric for the first time, or when a project has changed enough that its old rubric no longer matches what it ships.

## Catalog

The catalog is the set of rubric drafts shipped alongside `version-rubric`. Resolve its directory in this order and stop at the first hit:

1. `SPAI_RUBRIC_CATALOG` environment variable (session-only override).
2. `${CLAUDE_PLUGIN_ROOT}/skills/version-rubric/rubrics` (Claude Code plugin install).
3. `.agents/skills/spai-version-rubric/rubrics` (Codex and Antigravity project install).
4. `skills/version-rubric/rubrics` (running inside the SPAI repository itself).
5. `~/.agents/skills/spai-version-rubric/rubrics` or `~/.gemini/config/skills/spai-version-rubric/rubrics` (user-scope install).

Read the `rubrics/INDEX.md` in that directory first. It carries the type list, the detection signals, and the scoring rules; the per-type bodies are only read for the types that actually become candidates.

If no catalog is found, do not guess type names. Report that the catalog is missing, name the paths that were checked, and fall back to recommending the default rubric through `version-rubric`.

## Scan

Read only. Never modify a file, never install anything, never run a build.

1. **Inventory** — `git ls-files` for the tracked file list. Untracked build output and dependency directories are not evidence.
2. **Shape** — count files by extension and top-level directory. A repository whose tracked files are overwhelmingly documents or assets is graded by what those files promise, even when a stray script exists.
3. **Manifests** — read the dependency and packaging files that exist (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pubspec.yaml`, `Gemfile`, `*.csproj`, and the like). Dependency names are the strongest single source of type evidence.
4. **Entrypoints** — look for what the project hands to someone: published package metadata, executable names, server routes, deployment manifests, site config, exported assets.
5. **Distribution** — check `.github/workflows`, `Dockerfile`, `install.sh`, release automation, and store or registry configuration for how a release reaches its consumers.
6. **History** — `git log --oneline -30` and existing tags show what the project actually releases. A repository that only ever ships documents is graded as one.

Match what you found against the signal table in `INDEX.md` and score it by that file's rules: strong signal 2 points, weak signal 1 point, a signal counts once per type, candidates below 3 points are not reported, at most 3 candidates.

## Report

```md
## 프로젝트 유형 스캔

- 카탈로그: <path> (출처: 환경 변수 | 플러그인 | 프로젝트 설치 | 저장소 | 사용자 설치)
- 추적 파일: <n>개 · 주요 확장자: <ext>(<n>), <ext>(<n>)
- 배포 형태: <무엇이 소비자에게 닿는가>

| 순위 | 유형 | 점수 | 근거 경로 |
|---|---|---|---|
| 1 | <id> | <n> | `<path>`, `<path>` |
| 2 | <id> | <n> | `<path>` |

- 추천: <id> — <한 문장 이유>
- 함께 볼 유형: <id> (<이유>) | 없음
- 채택 시 초안: <catalog>/<id>.md
- 다음 조치: `version-rubric`으로 초안 작성 | 기본 기준 채택 | 유형 선택 필요
```

Rules for the report:

- Every candidate row carries at least one real path from this repository. A row without evidence is removed, not softened.
- Say what would be inherited: the recommended draft's `## 판정 순서` three questions, so the user judges the rubric and not just the type name.
- When two candidates are within 2 points, present them as a composite rather than picking one, and follow the merge rule in `INDEX.md`.
- When the top score is below 3, recommend the default rubric and say which signals were missing.
- Say which axis the recommendation grades on. A catalog draft grades by SemVer consumer compatibility; the default rubric grades by whether a human must step in. When the repository already has a rubric on the other axis, say so plainly — adopting the draft replaces the axis, it does not extend it.

## Handoff

1. Report the candidates and ask which type to adopt. One question, not a per-signal interrogation.
2. On a choice, read that type's body from the catalog and pass it to `version-rubric` (or the installed `spai-version-rubric`) as the draft, telling it that the draft came from the catalog and which type it is.
3. `version-rubric` owns the write, the `> 기준:` line, the confirmation before overwriting an existing rubric, and the commit.
4. If `version-rubric` is not installed, hand the draft to the user as a fenced block with its target path, and say that the file must be committed to reach clones and CI.

## Safety Rules

- Read-only. Do not write, move, or delete any file, including `.spai/versioning.md` and the catalog itself.
- Do not overwrite an existing rubric by way of the handoff. If `.spai/versioning.md` already exists, report the current rubric first and confirm the intent before recommending a replacement.
- Do not read file contents outside the repository, and do not report the contents of secret files. File names are evidence; secrets are not.
- Do not run package managers, builds, tests, or network commands to identify the type. The tracked files answer it.
- Do not invent a type that is absent from `INDEX.md`. A repository the catalog does not cover is reported as uncovered, with a note that a new type can be added from `_template.md`.
- Do not grade a release or write release notes; `github-release` owns that.
