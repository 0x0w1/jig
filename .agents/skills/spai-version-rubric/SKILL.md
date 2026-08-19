---
name: spai-version-rubric
description: "Use when creating, reviewing, or re-setting this repository's version grading rubric at .spai/versioning.md: adopt the SPAI default change-scale rubric, write a project-specific one, edit one grade, or reset to the default. Owns the rubric file; never runs a release."
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

> 기준: SPAI 기본 (변경 규모 축) | 직접 작성, <날짜>

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
- A missing optional section falls back to the default rubric below. No `## 강경 규칙` means no escalation rule.
- The `> 기준:` line records whether the default was adopted or the rubric was written for the project.
- Sections beyond these are read as context, not ignored. A project may add its own, such as a list of what counts as its public interface.

## Default Rubric

Offer this as-is. It grades by the scale of the change, which fits most projects.

```md
# 버전 정책

> 기준: SPAI 기본 (변경 규모 축), <날짜> 채택

## 판정 순서
1. 기존 기능의 단순 변경·수정인가? → `patch`
2. 기능이 추가·삭제되거나 크게 바뀌었는가? → `minor`
3. 프로젝트가 제공하는 가치나 세대가 바뀌었는가? → `major`

## 등급 정의
| bump | 정의 |
|---|---|
| `patch` | 기존 기능 범위 안의 수정. 버그 수정, 문구·문서 변경, 내부 구현 정리 |
| `minor` | 기능 단위의 추가·삭제·변경. 사용자가 새로 할 수 있는 일이 생기거나 없어짐 |
| `major` | 프로젝트의 방향·구조·제공 가치가 바뀜. 이전 버전과 같은 것으로 설명되지 않음 |
```

The default carries no `## 강경 규칙`. "A silent behavior change is always `major`" only makes sense for a tool with installed consumers; a project that needs it writes it into its own rubric.

A project whose releases ship documents rather than features usually grades by artifact instead: `patch` for document add/edit/delete, `minor` for changes to the tooling that manages the documents, `major` for a restructure. Write that through the project-specific path.

## Actions

Called without arguments. Determine the current state first, then confirm the user's intent.

| Action | When | Result |
|---|---|---|
| Review | file exists | Report the current rubric: path, source, kind, the three grades, commit state. Stop. |
| Create | file missing | Show the default, ask the binary question, write the file. |
| Re-set | file exists, user wants a different rubric | Show the current rubric, confirm, then replace it. |
| Edit one grade | file exists, one grade is wrong | Update that grade's question and definition only; preserve the rest. |
| Reset to default | file exists, user wants the default back | Replace with the default rubric and update the `> 기준:` line. |

## Procedure

1. Resolve the path and read the file if it exists. Report which of the three sources supplied the path, and note when it came from the environment variable that it is session-only.
2. If the file exists, summarize it and confirm the intent: keep, re-set, edit one grade, or reset to default. Keep ends the run.
3. For create or re-set, show the default rubric and ask one question: **use this rubric?**
   - Yes → write the default and record adoption in the `> 기준:` line.
   - No → ask, for each of the three grades, which changes in this project belong there. Put the user's own wording into `## 판정 순서` and `## 등급 정의`.
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
- Do not force a commit. If the user declines, report the uncommitted state.
- Preserve unrelated user changes.

## Final Report

```md
## 버전 판정 기준

- 경로: <path> (출처: 환경 변수 | 로컬 설정 | 관례)
- 기준: SPAI 기본 (변경 규모 축) | 직접 작성
- patch: <문항>
- minor: <문항>
- major: <문항>
- 변경: 생성 | 재설정 | <등급> 수정 | 기본 복귀 | 변경 없음
- 커밋: 완료 <commit subject> | 미커밋 (clone에 전파되지 않음)
- 다음 조치: 없음 | <조치>
```
