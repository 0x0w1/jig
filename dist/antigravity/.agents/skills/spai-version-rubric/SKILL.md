---
name: spai-version-rubric
description: "Use when creating, reviewing, or re-setting this repository's version grading rubric at .spai/versioning.md: adopt the SPAI default human-intervention rubric, write a project-specific one, edit one grade, or reset to the default. Owns the rubric file; never runs a release."
---

# Version Rubric

Use this repository skill to decide and maintain how this project grades `patch`, `minor`, and `major`. The decision lives in a project-owned Markdown file that `github-release` reads at release time.

Run this skill whenever the rubric needs to be created, reviewed, or changed. It is safe to run repeatedly.

## Rubric File

Resolve the rubric path in this order:

1. `SPAI_VERSION_RUBRIC` environment variable (session-only override).
2. `git config --local --get spai.versionRubric` (repository override; not propagated by clone).
3. `.spai/versioning.md` (the convention).

- `.spai/` is owned by the project, not by SPAI. The installer and `spai-update` never write or delete it, and `spai-doctor` never treats it as drift.
- The file must be committed. `git config --local` lives in `.git/config` and is not propagated by clone or CI checkout, so a config-only setup grades differently for different people.
- Never store state such as "the default was adopted" in a config key. That belongs in the file's `> 기준:` line, which is the single record of the decision.

### File Contract

Two required sections, four optional. The section titles are the contract.

```md
# 버전 정책

> 기준: SPAI 기본 (사람 개입 축) | 직접 작성, <날짜>

## 판정 순서        (required)
1. <question> → `patch`
2. <question> → `minor`
3. <question> → `major`

## 등급 정의        (required)
| bump | 정의 |

## 강경 규칙        (optional) conditions that always escalate
## 릴리즈 노트      (optional) note section order and titles
## 버전 형식        (optional) tag pattern, pre-1.0 handling, summary language
## 릴리즈 전 검증    (optional) commands to run before releasing
```

- `## 판정 순서` is asked in order and **stops at the first match**. A rubric cannot change that meaning.
- An optional section a rubric omits simply does not apply to that project. No `## 강경 규칙` means no escalation rule, even though the default below ships two.
- The `> 기준:` line records whether the default was adopted or the rubric was written for the project.
- Sections beyond these are read as context, not ignored. A project may add its own, such as a list of what counts as its public interface.

## Default Rubric

Offer this as-is. It grades by whether a human has to step in. Scale alone does not survive an AI-paced project: generations turn over fast enough that grading by size inflates `major` until the number carries no information.

```md
# 버전 정책

> 기준: SPAI 기본 (사람 개입 축), <날짜> 채택

## 판정 순서
1. 기존 기능 범위 안의 수정인가? → `patch`
2. 새로 할 수 있는 일이 생기거나 세대가 바뀌었지만, 쓰던 대로 계속 쓸 수 있는가? → `minor`
3. 제공하는 가치가 확장·제거·변경됐거나, 사람이 손대야 계속 쓸 수 있는가? → `major`

## 등급 정의
| bump | 정의 |
|---|---|
| `patch` | 기존 기능 범위 안의 수정. 버그 수정, 문구·문서 변경, 내부 구현 정리 |
| `minor` | 기능 추가·삭제·변경, 세대 교체. 새로 할 수 있는 일이 생기지만 쓰던 방식은 그대로 통함 |
| `major` | 제공 가치의 확장·제거·변경, 또는 사람이 손대야 하는 변경. 설정·파일·호출 방식을 고쳐야 계속 씀 |

## 강경 규칙
> 에러 없이 동작만 달라지는 변경은 `major`다. 크기와 무관하다.

> 스킬·프롬프트 지시문이 에이전트의 발화 조건을 바꾸면 최소 `minor`다.

## 버전 형식
- major 버전이 `0`인 동안 `major` 판정은 minor 자리를 올린다: `v0.Y.Z` → `v0.(Y+1).0`. 아직 1.0이 아니므로 제공 가치도 호출 방식도 언제든 바뀔 수 있다는 뜻이다. 판정 자체는 1.0 이후와 동일하게 하고, 릴리즈 보고에 `major` 판정을 남긴다.
- `v1.0.0` 이후 `major` 판정은 major 자리를 올린다. 이때부터 위 유예가 끝난다.
```

The default ships `## 강경 규칙` and `## 버전 형식` alongside the two required sections:

- The escalation rules exist because the break that matters in an AI project is a quiet one. No test suite confirms that a reworded instruction still fires on the same input, so the version number is the channel left for "a human should look at this."
- While the major version is `0`, `minor` and `major` land on the same position, so the escalation rules cost nothing yet and the `> 기준:` line says so. They begin to bind at `v1.0.0`, which is why they are settled before then.
- A project that wants neither section removes them; both are optional by contract.

A project whose releases ship documents rather than features usually grades by artifact instead: `patch` for document add/edit/delete, `minor` for changes to the tooling that manages the documents, `major` for a restructure. That rubric and a dozen others are already written; take one from the catalog below instead of drafting it.

## Type Catalog

`rubrics/` ships next to this skill and holds one ready draft per project type. Every file in it is a complete rubric: copy it to the resolved rubric path, fill the `> 기준:` date, and adjust the interface list to what this project actually promises.

```text
rubrics/
├── INDEX.md            # type list, detection signals, scoring and merge rules
├── _template.md        # skeleton for a type the catalog does not cover yet
├── common.md           # SemVer principles that hold across every type
├── developer/          # graded by call, import, and deployment contracts
└── non-developer/      # graded by the documents, assets, and data themselves
```

- Read `INDEX.md` first. It is the only file that lists the types, so a draft not indexed there is invisible to the scan.
- The `non-developer/` drafts title their interface section `## 소비자와 약속한 것`. It means the same thing as `## 공개 인터페이스`; the reader is not a developer.
- Do not read every body. Read `INDEX.md`, pick the type, read that one file.
- The catalog is payload: `spai-update` replaces it. Never edit a catalog file to record a project's decision — the decision lives in the resolved rubric path.

When the project type is not obvious, run `rubric-scan` (or the installed `spai-rubric-scan`) first. It scans the repository, scores it against `INDEX.md`, and hands back a type with the paths that produced it. This skill still owns the write.

## Actions

Called without arguments. Determine the current state first, then confirm the user's intent.

| Action | When | Result |
|---|---|---|
| Review | file exists | Report the current rubric: path, source, kind, the three grades, commit state. Stop. |
| Create | file missing | Show the default, ask the binary question, write the file. |
| Adopt a type | the project has a clear type, or `rubric-scan` handed one over | Write that catalog draft as the rubric, dated and with the interface list adjusted. |
| Re-set | file exists, user wants a different rubric | Show the current rubric, confirm, then replace it. |
| Edit one grade | file exists, one grade is wrong | Update that grade's question and definition only; preserve the rest. |
| Reset to default | file exists, user wants the default back | Replace with the default rubric and update the `> 기준:` line. |

## Procedure

1. Resolve the path and read the file if it exists. Report which of the three sources supplied the path, and note when it came from the environment variable that it is session-only.
2. If the file exists, summarize it and confirm the intent: keep, re-set, edit one grade, or reset to default. Keep ends the run.
3. For create or re-set, show the default rubric and ask one question: **use this rubric?**
   - Yes → write the default and record adoption in the `> 기준:` line.
   - No → offer the catalog before drafting from scratch. Read `rubrics/INDEX.md`, name the types that fit what this repository ships, and let the user pick one; when the type is unclear, run `rubric-scan` and use its recommendation. A chosen draft is written as-is except for the `> 기준:` line and the interface list.
   - No catalog type fits → ask, for each of the three grades, which changes in this project belong there. Put the user's own wording into `## 판정 순서` and `## 등급 정의`.
4. If the user skips the question or does not answer, adopt the default and record it. Do not ask again.
5. Keep the user's vocabulary. Only normalize the sentence shape into `<question> → \`patch\`` form. Translating their words into SPAI terms such as "silent behavior change" makes the next release grade differently than they intended.
6. Write the file, creating `.spai/` when missing. Then hand the commit to the repository's flow: if `develop-task-flow` (or the installed `spai-develop-task-flow`) exists, follow it with a `chore/<slug>` branch, a `chore:` squash commit, and a `develop` push. Otherwise propose a normal commit on the current branch.
7. Report.

## Safety Rules

- Never overwrite an existing rubric without showing its current content and getting explicit confirmation.
- Do not create `.bak` copies. The file is tracked, so git history is the record. Warn before overwriting when the file is untracked or has uncommitted changes.
- Do not grade a release or write release notes; `github-release` owns that.
- Do not touch branches, branch protection, tags, releases, or GitHub settings.
- Do not write anything outside the resolved rubric path and its parent `.spai/` directory.
- Do not modify `rubrics/`. It is shipped payload that `spai-update` replaces; a project's decision belongs in the rubric file.
- Do not force a commit. If the user declines, report the uncommitted state.
- Preserve unrelated user changes.

## Final Report

```md
## 버전 판정 기준

- 경로: <path> (출처: 환경 변수 | 로컬 설정 | 관례)
- 기준: SPAI 기본 (사람 개입 축) | 카탈로그 <type> | 직접 작성
- patch: <문항>
- minor: <문항>
- major: <문항>
- 변경: 생성 | 재설정 | <등급> 수정 | 기본 복귀 | 변경 없음
- 출처 초안: 없음 | rubrics/<audience>/<type>.md
- 커밋: 완료 <commit subject> | 미커밋 (clone에 전파되지 않음)
- 다음 조치: 없음 | <조치>
```
