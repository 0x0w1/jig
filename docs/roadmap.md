# SPAI Roadmap

> 방향 아이디에이션 기록. 착수 여부와 무관하게 후보를 트리거 조건과 함께 보존한다.

## 정체성

SPAI 초기 버전은 **개인 사이드 프로젝트의 CLI 에이전트 하네스 설정 도구**다. 지원 대상은 Claude Code, Codex, Antigravity CLI.

일반 스킬 마켓플레이스와의 차별점:

1. **저장소 상태까지 수렴** — 세션 스킬 배포에 그치지 않고 브랜치 모델·branch protection·릴리즈 규율이라는 저장소 상태를 `github-sync`(수렴)와 `spai-doctor`(진단)로 관리
2. **에이전트 횡단 일관성 + 수명주기** — 하나의 절차 원본(`skills/`)을 여러 CLI로 렌더링하고, 버전 스탬프·`spai-update`·`spai-doctor`로 설치 이후를 관리

## 현재 제공

- installer: 최신 릴리즈 태그 고정 설치, `--version` 롤백, `--skills` 선택 설치(`manifest.tsv` 카탈로그), `--flow solo-cli|team-pr` 프로필
- workflow 스킬 3종: `develop-task-flow`, `github-release`, `github-sync`
- 수명주기 스킬 2종: `spai-update`, `spai-doctor`
- Claude Code 플러그인 마켓플레이스 배포 (`spai`, `spai-team-pr`)

## 방향 후보 (보류 중, 트리거 조건부)

| 후보 | 내용 | 착수 트리거 |
|---|---|---|
| **A. 절차 확장** | 같은 도메인의 절차 추가: `hotfix-flow`(main 긴급 수정→develop 역반영), `issue-triage`, `dependency-update`, `repo-hygiene`(doctor 확장 감사) 등 | 실사용에서 반복 행동이 관찰될 때, 한 번에 1개씩. 선제작 금지 (스킬 분량 최소화 원칙) |
| **B. 절차 준수 검증 (conformance)** | 에이전트가 절차를 실제로 따랐는지 기계 검증. 릴리즈 후 커밋·태그·노트가 규칙대로인지 사후 감사. CI에서도 실행 가능한 검사 스크립트 형태로 설계하면 C의 CI 감사 요소를 겸함 | 절차 위반 사례가 실사용에서 축적될 때 |
| **C. 팀 도입 채널** | 온보딩(원라이너 1회 = 팀 규칙 동기화), 팀원별 드리프트 감시, CI 감사, 조직별 flow 파라미터(승인 수 등). 새 스킬 증가 거의 없음 — 기존 도구의 실행 맥락 확장 | 실제 팀 사용자가 등장할 때. B가 CI 실행형이면 절반은 해결됨 |
| **D. engine/content 분리 (registry)** | installer·manifest·수명주기(engine)와 스킬 내용(content)을 분리해 타 조직이 자기 절차를 SPAI 엔진으로 배포. `REPO_RAW_URL` 오버라이드가 이미 절반 — 남은 건 하드코딩 제거와 절차 저장소 스캐폴드 | 외부 수요 신호(fork, 이슈, 절차 배포 요청)가 보일 때 |

## 다음 단계

- 기존 사이드 프로젝트들에 실전 적용: 설치/업데이트 재실행 → `github-sync` 수렴 → `spai-doctor` 진단 → 마찰 수집
- 여기서 나온 반복 행동·위반 사례가 A/B의 착수 재료가 된다
