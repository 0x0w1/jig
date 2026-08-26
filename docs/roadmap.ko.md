# jig Roadmap

[English](roadmap.md)

> 방향 아이디에이션 기록. 착수 여부와 무관하게 후보를 트리거 조건과 함께 보존한다.

## 정체성

jig 초기 버전은 **개인 사이드 프로젝트의 CLI 에이전트 하네스 설정 도구**다. 지원 대상은 Claude Code, Codex, Antigravity CLI.

일반 스킬 마켓플레이스와의 차별점:

1. **저장소 상태까지 수렴** — 세션 스킬 배포에 그치지 않고 브랜치 모델·branch protection·릴리즈 규율이라는 저장소 상태를 `github-sync`(수렴)와 `jig-doctor`(진단)로 관리
2. **에이전트 횡단 일관성 + 수명주기** — 하나의 절차 원본(`skills/`)을 여러 CLI로 렌더링하고 버전 스탬프·`jig-update`·`jig-doctor`로 설치 이후를 관리

## 현재 제공

- installer: 최신 릴리즈 태그 고정 설치, `--version` 롤백, `--skills` 선택 설치(`manifest.tsv` 카탈로그, codex/antigravity 전용)
- workflow 스킬 3종: `develop-task-flow`, `github-release`, `github-sync`
- 수명주기 스킬 2종: `jig-update`, `jig-doctor`
- 온보딩 스킬 1종: `project-setup` (설치 후 저장소별 GitHub 프로필 선택·검증)
- 문서 스킬 3종: `readme`(README 생성·갱신), `version-rubric`(버전 판정 기준 확정, 유형별 카탈로그 배포), `rubric-scan`(저장소 스캔 후 기준 추천)
- 로컬 가드 2층: `github-sync`가 설치하는 git `pre-push` hook(전 CLI 공통) + Claude Code 플러그인 PreToolUse hook(`--no-verify` 우회 차단)
- 배포 방식: Claude Code는 플러그인 마켓플레이스(`jig@jig`, 호스트가 `/jig:<skill>`로 네임스페이스), Codex/Antigravity는 `jig-` prefix 스킬 파일

병합 흐름은 **하나뿐이다**: 로컬 `git merge --squash` → `develop` 직접 push, Pull Request 없음. 팀 흐름은 아래 C 후보로 보류돼 있다.

## 방향 후보 (보류 중, 트리거 조건부)

| 후보 | 내용 | 착수 트리거 |
|---|---|---|
| **A. 절차 확장** | 같은 도메인의 절차 추가: `hotfix-flow`(main 긴급 수정→develop 역반영), `issue-triage`, `dependency-update`, `repo-hygiene`(doctor 확장 감사) 등 | 실사용에서 반복 행동이 관찰될 때, 한 번에 1개씩. 선제작 금지 (스킬 분량 최소화 원칙) |
| **B. 절차 준수 검증 (conformance)** | 에이전트가 절차를 실제로 따랐는지 기계 검증. 릴리즈 후 커밋·태그·노트가 규칙대로인지 사후 감사. CI에서도 실행 가능한 검사 스크립트 형태로 설계하면 C의 CI 감사 요소를 겸함 | 절차 위반 사례가 실사용에서 축적될 때 |
| **C. 팀 도입 채널** | 온보딩(원라이너 1회 = 팀 규칙 동기화), 팀원별 드리프트 감시, CI 감사, 조직별 flow 파라미터(승인 수 등). PR 기반 병합 흐름(`team-pr`) 복원 포함 — 설계는 아래 기록 참조 | 실제 팀 사용자가 등장할 때. B가 CI 실행형이면 절반은 해결됨 |
| **D. engine/content 분리 (registry)** | installer·manifest·수명주기(engine)와 스킬 내용(content)을 분리해 타 조직이 자기 절차를 jig 엔진으로 배포. `REPO_RAW_URL` 오버라이드가 이미 절반 — 남은 건 하드코딩 제거와 절차 저장소 스캐폴드 | 외부 수요 신호(fork, 이슈, 절차 배포 요청)가 보일 때 |
| **E. Codex/Antigravity 네이티브 hook** | git pre-push 가드를 두 CLI의 네이티브 PreToolUse hook으로도 제공 (Codex `hooks.json`은 experimental·기본 비활성, Antigravity는 사용자 소유 설정 파일 편집 필요) | 해당 CLI hook의 GA/안정화 + git hook으로 못 막는 실사례 발생 |

## 설계 기록: 스킬 소유권 마커 (제거됨)

v0.2.0 이전에는 배포 payload에 `<!-- jig:owned skill=<name> -->` 마커를 넣었다. installer는 마커 없는 파일을 건너뛰고 버전 스탬프를 소유권 대장으로 삼아 구버전을 승계하고 선택에서 빠진 파일은 고아로 보고했다. 플러그인 네임스페이스(Claude Code)와 `jig-` prefix(Codex/Antigravity)로 대체하면서 전부 제거했다. 호스트가 제공하는 기능을 재구현하지 않는다는 원칙의 사례로 남긴다.

## 설계 기록: team-pr flow (제거됨, C 착수 시 복원 대상)

한때 구현돼 있던 PR 기반 팀 흐름이다. 실제 팀 사용자가 없어 유지 비용만 발생해 제거했고 복원에 필요한 설계만 여기 남긴다. 원본 파일은 git 히스토리에 있다.

**flow 프로필 메커니즘** (v0.2.0에서 `--flow` 옵션과 스탬프의 `flow=` 필드까지 완전 제거됨)

- installer가 `--flow <flow>`(`JIG_FLOW`)를 받아 `manifest.tsv` 2열의 지원 flow 목록과 대조하고 선택된 flow를 버전 스탬프에 `flow=<flow>`로 기록했다.
- 스킬 원본은 `skills/<skill>/SKILL.md`(기본)와 `skills/<skill>/SKILL.<flow>.md`(변형)로 두고 변형이 있으면 그것을, 없으면 기본을 배포했다. installer는 변형 payload가 404면 기본으로 폴백했다.
- Claude Code 플러그인은 flow별로 하나씩 빌드했다(`jig`, `jig-team-pr`). 플러그인 payload 안에서는 변형이 `SKILL.md`로 해소된 상태여야 했다.
- `jig-doctor`는 스탬프의 flow에 맞는 payload와 `cmp`해 드리프트를 판정하고 flow별로 다른 branch protection 기대값을 검사했다.

**team-pr가 solo-cli와 달랐던 지점**

- `develop-task-flow`: 로컬 squash merge 대신 브랜치 push → `develop` 대상 PR 생성 → 체크 통과 시 `gh pr merge --squash`. PR 본문은 `## Summary`(한국어 릴리즈 노트용 불릿) / `## Details` / `## Tests` 구성. `develop` 직접 push 금지. 병합이 막히면 PR을 열어둔 채 차단 사유를 보고.
- `github-sync`: `develop`에 `required_pull_request_reviews` 적용(승인 수는 팀 정책, `0` 허용), `main`은 릴리즈 fast-forward를 위해 직접 push 허용. 양쪽 모두 force push·삭제 차단.
- `github-release`: 차이 없음. 릴리즈는 두 flow 모두 CLI 주도(`develop:main` fast-forward + 태그 + `gh release create`).

**복원 시 주의**

- 복원하면 스킬 원본이 flow마다 갈라져 유지 비용이 두 배가 된다. C 후보의 "조직별 flow 파라미터"처럼 하나의 절차를 파라미터로 분기하는 설계를 먼저 검토할 것.
- `validate-dist.sh`에 flow 변형과 `team-pr` 문자열을 막는 가드가 있다. 복원 시 함께 풀어야 한다.

## 다음 단계

- 기존 사이드 프로젝트들에 실전 적용: 설치/업데이트 재실행 → `github-sync` 수렴 → `jig-doctor` 진단 → 마찰 수집
- 여기서 나온 반복 행동·위반 사례가 A/B의 착수 재료가 된다
