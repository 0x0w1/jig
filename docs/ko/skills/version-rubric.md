# Version Rubric

<!-- jig:skill-source-digest af9061e8cf58f4efbba7e0f7ea0b9bf09e6dc67b -->

[English](../../en/skills/version-rubric.md) · [스킬 index](index.md) · [Rubric 계약](../version-rubric.md)

## 개요

`version-rubric`은 `JIG_VERSION_RUBRIC`, local `jig.versionRubric`, `.jig/versioning.md` 순서로 해석한 project-owned version policy를 독점적으로 생성·review·re-set·edit합니다. release를 실행하지 않습니다.

## 사용 시점

rubric이 없을 때, project의 `patch`·`minor`·`major` 판정 방식을 review할 때, catalog type adoption, grade 하나 edit, default reset, legacy Korean section title의 명시적 convert에 사용합니다.

## 실행 방법과 file 계약

- Claude Code: `/jig:version-rubric`
- Codex: `jig:version-rubric`
- Antigravity: `jig-version-rubric`
- 필수 section: `## Decision Order`, `## Grade Definitions`
- 선택 section: `## Hard Rules`, `## Interface Paths`, `## Hotfix Triggers`, `## Release Notes`, `## Version Format`, `## Pre-Release Checks`

`## Interface Paths`는 path glob을 그 아래 변경이 가질 수 있는 최저 등급에 대응시킵니다. 덕분에 `develop-task-flow`와 `github-release`가 산문 목록을 눈으로 읽는 대신 `git diff --name-only`로 시작 등급을 계산합니다. 처음 걸리는 행이 이기고, 여기서 나온 바닥은 참고값이라 이유를 남기면 더 낮게 낼 수 있습니다. 카탈로그의 모든 유형 초안이 이 표를 갖고 있으므로 유형을 채택할 때는 glob이 실제 트리와 맞는지 확인하고, 기본 rubric은 표 없이 나가며 사용자가 요청할 때만 덧붙입니다.

legacy Korean title도 유효하지만 English title과 한 파일에서 섞으면 안 됩니다. `> Basis:` line은 default adoption, catalog type, project-specific 원천을 기록합니다. clone과 CI가 같은 기준을 쓰도록 file을 commit해야 합니다.

## 작업 흐름

```mermaid
flowchart TD
    Resolve[해석된 기준과 요청 확인] --> Review{검토만 요청?}
    Review -- Yes --> Report[쓰기 없이 보고]
    Review -- No --> Choice{구체적 기준 변경 승인됨?}
    Choice -- Yes --> Write[승인된 변경만 작성]
    Choice -- No --> Propose[현재 기준·제안 표시 후 질문]
    Propose -- 수락 --> Write
    Propose -- 무응답 --> Report
    Propose -- 거절 --> Catalog[카탈로그 제안 또는 프로젝트 결정 수집]
    Catalog --> Choice
    Write --> Scope{승인된 Git 상한?}
    Scope -- Local --> Uncommitted[미커밋 보고]
    Scope -- Commit --> Commit[커밋만 위임]
    Scope -- Land --> Flow[승인된 저장소 흐름 위임]
```

default는 human intervention을, catalog draft는 SemVer consumer compatibility를 판정합니다. 두 axis는 대안이며 question을 섞지 말고 하나를 전체로 adoption해야 합니다.

## 읽기·변경 범위

해석된 기준·Git 상태와 필요한 경우 카탈로그 목록·관련 초안 하나, 작업에 필요한 저장소 맥락을 읽습니다. 승인된 기준 변경만 작성하고 검토는 읽기 전용입니다. Git 작업은 채택된 `develop-task-flow`에 현재 제한과 명시적으로 승인된 기존 정책을 전달합니다. 로컬 변경은 미커밋, 커밋만 승인되면 병합 전 중단, 이미 승인된 반영은 재확인 없이 진행합니다. 기준 스킬은 브랜치·태그·보호·릴리즈를 직접 관리하지 않으며 카탈로그는 배포 자료로 유지합니다.

## 판단 지점과 안전 규칙

- 기존 기준을 보여주고 구체적 교체에 대한 명시적 결정을 따릅니다. 이미 받은 결정은 다시 묻지 않습니다.
- 침묵은 승인이 아닙니다. create·re-set 질문에 답이 없으면 아무것도 쓰지 않고 default를 제안으로 보고한 뒤 멈춥니다. 요청이 이미 default 사용을 승인했을 때만 재질문 없이 씁니다. 기존 기준 교체도 명시적인 교체 결정이 필요합니다. 일반적인 설치 요청이나 침묵은 승인이 아닙니다.
- 사용자의 언어와 용어를 보존합니다. 임의 rephrase는 향후 grading을 바꾸기 때문입니다.
- 무단 translate·retitle, `.bak` 생성, catalog 편집, release grading, GitHub 설정 변경, 강제 commit을 하지 않습니다.
- untracked·uncommitted rubric을 덮어쓰기 전에 경고합니다.

## 결과물

path·source, basis, title spelling, 3개 grade question, action, draft source, commit state, 다음 조치를 보고합니다.

## 관련 스킬

- [`rubric-scan`](rubric-scan.md): write 없이 catalog type 추천
- [`github-release`](github-release.md): 확정된 rubric 읽기
- [`jig-setup`](jig-setup.md): rubric 누락 시 생성 위임
- [`jig-doctor`](jig-doctor.md): missing·broken·uncommitted rubric 진단

## 원본

- [`skills/version-rubric/SKILL.md`](../../../skills/version-rubric/SKILL.md)
- [Rubric catalog](../../../skills/version-rubric/rubrics/INDEX.md)
- [사용자 계약](../version-rubric.md)
