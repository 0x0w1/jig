# jig Roadmap

[English](../en/roadmap.md)

> 방향 아이디에이션 기록. 착수 여부와 무관하게 후보를 트리거 조건과 함께 보존한다.

## 정체성

jig 초기 버전은 **개인 사이드 프로젝트의 CLI 에이전트 하네스 설정 도구**다. 지원 대상은 Claude Code, Codex, Antigravity CLI.

일반 스킬 마켓플레이스와의 차별점:

1. **저장소 상태까지 수렴** — 세션 스킬 배포에 그치지 않고 브랜치 모델·branch protection·릴리즈 규율이라는 저장소 상태를 `github-sync`(수렴)와 `jig-doctor`(진단)로 관리
2. **에이전트 횡단 일관성 + 수명주기** — 하나의 절차 원본(`skills/`)을 여러 CLI로 렌더링하고 버전 스탬프·`jig-update`·`jig-doctor`로 설치 이후를 관리

## 현재 제공

- installer: 최신 릴리즈 태그 고정 설치, `--version` 롤백, `--skills` 선택 설치(`manifest.tsv` 카탈로그, codex/antigravity 전용)
- workflow 스킬 4종: `develop-task-flow`(일반 작업), `hotfix-flow`(`develop` 대기열을 기다릴 수 없는 릴리즈 결함), `github-release`, `github-sync`
- 수명주기 스킬 2종: `jig-update`, `jig-doctor`
- 온보딩 스킬 1종: `jig-setup` (설치 후 저장소별 GitHub 프로필 선택·검증)
- 문서 스킬 3종: `readme`(README 생성·갱신), `version-rubric`(버전 판정 기준 확정, 유형별 카탈로그 배포), `rubric-scan`(저장소 스캔 후 기준 추천)
- 저장소 정리 스킬 1종: `repo-hygiene`(브랜치·태그·기준 파일·잔여물 점검, 사용자가 지목한 것만 삭제)
- 준수 검증 스킬 1종: `conformance-audit`(도입 기준선부터 이력을 절차와 대조, 읽기 전용, 위반 시 0이 아닌 종료 코드, CI 실행 가능)
- 로컬 가드 2층, 전 CLI 공통: `github-sync`가 설치하는 git `pre-push` hook + push 명령을 실행 전에 검사하는 PreToolUse hook(`--no-verify` 우회 차단). 후자는 Claude Code 플러그인 안에 들어 있고, Codex(`.codex/hooks.json`)와 Antigravity(`.agents/hooks.json`)에는 `github-sync`가 네이티브 hook 항목으로 설치한다. 셋 모두 하나의 `guard-push.sh` 원본을 실행한다. 두 겹 모두 `main`으로 가는 길을 `develop:main`과 `hotfix/<slug>:main` 둘로만 허용
- 릴리즈 이전에 시작하는 판정: `develop-task-flow`가 squash 커밋마다 `Release-Grade` trailer를 기록하고, `github-release`가 범위 내 최고값을 내리지 않는 하한으로 삼는다. 기준 파일의 `## Interface Paths` 표에서 계산한 참고용 바닥이 함께 쓰인다
- 배포 방식: Claude Code는 플러그인 마켓플레이스(`jig@jig`, 호스트가 `/jig:<skill>`로 네임스페이스), Codex/Antigravity는 `jig-` prefix 스킬 파일

병합 흐름은 **하나뿐이다**: 로컬 `git merge --squash` → `develop` 직접 push, Pull Request 없음. 팀 흐름은 아래 C 후보로 보류돼 있다.

## 방향 후보 (보류 중, 트리거 조건부)

| 후보 | 내용 | 착수 트리거 |
|---|---|---|
| **A. 절차 확장** | ~~`hotfix-flow`~~·~~`repo-hygiene`~~ 제공 완료. 폐기한 둘의 사유는 아래 설계 기록 참조 | 종료. 절차를 더 추가하려면 별도 후보와 별도 트리거가 필요 |
| **B. 절차 준수 검증 (conformance)** | ~~`conformance-audit`으로 제공 완료~~: 도입 기준선부터 커밋 subject, `Release-Grade` 적용률, 태그 형식·위치, `main`/`develop` 불변식을 판정하는 읽기 전용 검사 스크립트와 스킬. 종료 코드가 CI 계약이므로 C의 CI 감사 요소를 겸한다 | 착수·완료. 남은 일은 검사 항목이 실제 위반과 맞는지 관찰하고, 감사가 놓친 위반이 나올 때만 항목을 늘리는 것 |
| **C. 팀 도입 채널** | 온보딩(원라이너 1회 = 팀 규칙 동기화), 팀원별 드리프트 감시, CI 감사, 조직별 flow 파라미터(승인 수 등). PR 기반 병합 흐름(`team-pr`) 복원 포함 — 설계는 아래 기록 참조 | 실제 팀 사용자가 등장할 때. B가 CI 실행형이면 절반은 해결됨 |
| **D. engine/content 분리 (registry)** | installer·manifest·수명주기(engine)와 스킬 내용(content)을 분리해 타 조직이 자기 절차를 jig 엔진으로 배포. `REPO_RAW_URL` 오버라이드가 이미 절반 — 남은 건 하드코딩 제거와 절차 저장소 스캐폴드 | 외부 수요 신호(fork, 이슈, 절차 배포 요청)가 보일 때 |
| **E. Codex/Antigravity 네이티브 hook** | ~~제공 완료~~: `github-sync`가 두 CLI에 push 가드를 네이티브 PreToolUse hook 항목으로 설치한다. 항목은 이미 배포 중인 `guard-push.sh` payload를 가리킨다. 아래 설계 기록 참조 | 종료. 착수 시점에 트리거를 다시 읽었다. Codex hook은 안정화돼 기본 활성이 됐고, git hook으로 못 막는 사례는 구조적인 것(`--no-verify`)으로 Claude Code에서는 이미 막고 있었다 — 세 CLI의 정합성이 착수 사유다 |

## 설계 기록: issue-triage·dependency-update (폐기)

둘 다 후보 A에 적혀 있었고 만들지 않는다. 다시 제안되지 않도록 사유를 남긴다.

**`issue-triage`**는 저장소 상태를 수렴하지 않는다. 그것이 이 프로젝트가 일반 스킬 마켓플레이스와 긋는 선이다. 이슈 분류는 `gh issue list`로 이미 되는 일반 에이전트 작업이고, `github-sync`는 의도적으로 라벨을 동기화하지 않는다. 라벨을 안 쓰기로 한 프로젝트가 라벨 워크플로를 배포할 이유가 없다. 개인 사이드 프로젝트 규모에서는 분류 자체가 몇 분 읽는 일이다.

**`dependency-update`**는 호스트가 이미 제공한다. Dependabot과 Renovate가 무료로, jig에 없고 앞으로도 없을 언어별 지식까지 갖고 처리한다. jig는 shell과 Markdown이다. 더할 수 있는 건 갱신을 `develop-task-flow`에 태우는 것뿐인데 이미 있는 스킬 위의 얇은 래퍼다. 만들면 바로 아래 기록된 실수를 반복하게 된다.

## 설계 기록: 네이티브 push hook (E와 함께 제공)

`manage-native-hooks.sh`의 형태를 정한 결정들이다. 다시 논쟁하지 않도록 남긴다.

- **가드 원본은 하나.** `skills/github-sync/assets/guard-push.sh`가 유일한 push 가드다. Claude Code 플러그인의 `hooks/guard-push.sh`는 빌드 시 복사본이다. 이 스크립트가 두 payload 형태(Claude Code·Codex의 `tool_input.command`, Antigravity의 `toolCall.args.CommandLine`)를 읽고 각 호스트가 읽는 계약으로 답한다.
- **프로젝트 스코프만.** 사용자 스코프 `~/.codex/hooks.json`이나 `~/.gemini/config/hooks.json`에 항목을 넣으면 jig가 설치되지 않은 저장소까지 그 머신의 모든 저장소가 가드를 받는다. jig-managed project 밖의 동작이므로 제공하지 않는다.
- **항목은 경로만 담는다.** Codex는 hook 정의가 바뀔 때마다 사용자에게 재신뢰를 요구한다. 그래서 판정 로직은 `jig-update`가 갱신하는 payload 파일에 두고, hooks.json 항목은 릴리즈 사이에 바뀌지 않는다.
- **Codex 신뢰는 사용자의 단계다.** Codex는 비관리 hook을 사용자가 `/hooks`에서 검토한 뒤에만 실행한다. jig는 그 단계를 매번 보고하고 대신 수행하지 않는다. `jig-doctor`는 신뢰 상태를 볼 수 없으므로 hook이 활성이라고 단정하지 않고 그렇게 말한다.
- **Antigravity는 stdout JSON으로만 답한다.** 그 런타임은 크래시나 0이 아닌 종료를 허용으로 취급하므로, 그 호스트에서는 가드가 exit 0으로 끝나며 `{"decision":"deny","reason":...}`을 출력한다.
- **검증.** Codex는 실측했다. `.codex/hooks.json`이 있는 프로젝트에서 `codex exec`가 PreToolUse hook을 실행하고 `tool_input.command`를 넘기며 exit 2를 차단으로 처리했다. Antigravity는 문서화된 계약을 따른다. 제공 시점에 Antigravity CLI가 없었으므로 첫 실제 설치에서 항목의 명령이 해석되는지와 `git push --no-verify origin main`이 거부되는지 확인해야 한다.
- **하지 않은 것.** Codex 관리형 hook(`requirements.toml`)은 팀 채널(후보 C)의 일이다. Antigravity의 `ask`·`deny_unless_prior_grant` 결정은 쓰지 않는다. jig 정책의 답은 둘이다.

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

- 기존 사이드 프로젝트들에 실전 적용: 설치/업데이트 재실행 → `github-sync` 수렴 → `jig-doctor` 진단 → `repo-hygiene` 정리 → 마찰 수집
- 각 저장소에 `conformance-audit`을 돌리고 그 발견이 실제 상태와 맞는지 대조한다. 정상 저장소에서 울리는 검사는 저장소가 아니라 감사의 결함이다
- A·B·E는 종료됐다. C·D는 트리거 조건부로 남는다
