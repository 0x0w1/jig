# SPAI

**Scaffolded Procedures for AI Agents** — AI 에이전트 CLI 환경에 저장소 운영 절차를 설치하는 하네스 설정 도구입니다.

[English](README.md)

[빠른 시작](#빠른-시작) · [스킬](#스킬) · [문서](#문서) · [업데이트](#업데이트) · [License](#license)

## 프로젝트 소개

사이드 프로젝트마다 AI 에이전트(Claude Code, Codex, Antigravity CLI)를 쓰다 보면, 브랜치 규칙·커밋 규칙·릴리즈 절차를 프로젝트마다·에이전트마다 다시 알려줘야 합니다. SPAI는 이 반복을 없앱니다: 같은 절차 스킬 세트를 어느 에이전트 환경에나 설치하고 설치 이후의 업데이트와 상태 진단까지 관리합니다.

지원 대상: **Claude Code**(권장), **Codex**, **Antigravity CLI**

## 빠른 시작

![SPAI 빠른 시작: CLI 하나에 설치하고, project-setup으로 프로필·버전 기준·브랜치 수렴·점검을 끝낸 뒤, spai-doctor로 확인하고, 이후 작업은 develop-task-flow와 github-release로 흘러갑니다](docs/assets/quick-start.svg)

준비물: git 저장소, 그리고 Codex·Antigravity는 `curl` 또는 `wget`. GitHub 연동까지 하려면 `gh` 로그인이 필요하지만 스킬 설치 자체에는 필요 없습니다.

### 1. 설치 — 쓰는 CLI 하나만

**Claude Code**(권장) — 세션 안에서 실행합니다. 플러그인 호스트가 설치·업데이트·삭제를 관리하고, push 명령을 실행 전에 검사하는 `PreToolUse` 가드 hook은 여기에만 들어 있습니다.

```text
/plugin marketplace add 0x0w1/spai
/plugin install spai@spai
```

**Codex**와 **Antigravity CLI** — 저장소 루트에서 실행합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target codex --scope project        # 또는 --target antigravity
```

옵션, 설치 위치, 스킬 네임스페이스, 제거는 [설치 가이드](docs/installation.md)에 있습니다.

### 2. 저장소에 연결

에이전트 세션에서 `project-setup`을 실행합니다. Claude Code는 `/spai:project-setup`, Codex와 Antigravity는 `spai-project-setup`입니다.

한 번 실행으로 네 가지가 끝납니다.

1. 이 저장소가 쓸 GitHub 프로필 선택·검증 (전역 active 계정은 건드리지 않음)
2. 버전 판정 기준을 정해 `.spai/versioning.md`에 기록
3. `github-sync`로 `main`·`develop` 브랜치 수렴, branch protection은 물어보고 적용 (public 저장소는 무료, private은 유료 플랜에서만 가능한 선택 기능)
4. `spai-doctor`로 설치 상태 점검

### 3. 확인

`/spai:spai-doctor` (Codex·Antigravity는 `spai-doctor`)를 실행하면 설치 버전, 파일 드리프트, 브랜치 보호, GitHub 프로필, 기준 파일 상태를 read-only로 보고합니다. 고칠 것이 있으면 어느 스킬이 고치는지까지 알려줍니다.

이후로는 스킬 이름을 부르거나 하려는 일을 말하면 에이전트가 알아서 고릅니다.

## 스킬

SPAI는 일반 스킬 모음과 달리 세션 절차만 배포하지 않습니다. 브랜치 모델·branch protection·릴리즈 규율이라는 *저장소 상태*를 함께 수렴하고, 설치 이후를 `spai-update`와 `spai-doctor`로 관리합니다. 하나의 절차 원본(`skills/`)을 각 CLI의 네이티브 형식으로 렌더링합니다 — Claude Code는 플러그인, Codex와 Antigravity는 `spai-` prefix 파일입니다.

- **`develop-task-flow`** — `feature/fix/chore` 브랜치에서 작업 후 `develop`에 squash merge
- **`github-release`** — `develop`을 `main`으로 fast-forward 승격, 버전 계산 후 태그·릴리즈 생성
- **`github-sync`** — `main`/`develop` 브랜치 동기화, 플랜이 허용하면 branch protection 제안, 로컬 `pre-push` 가드 설치
- **`project-setup`** — SPAI 설치 후 저장소별 GitHub CLI 프로필 설정·검증
- **`spai-update`** — 설치본을 최신 SPAI 릴리즈로 업데이트
- **`spai-doctor`** — 설치 상태 진단(버전·드리프트·보호 규칙·레거시), read-only
- **`readme`** — 프로젝트 타입 판정 후 `README.md` 생성, 기존 README는 코드와 대조해 드리프트 수정
- **`version-rubric`** — 버전 판정 기준(`patch`/`minor`/`major`)을 `.spai/versioning.md`에 정함. 유형별 기준 카탈로그를 함께 배포
- **`rubric-scan`** — 저장소를 스캔해 프로젝트 유형을 판정하고 카탈로그에서 맞는 기준을 추천, read-only

작업 병합 방식은 **solo-cli 하나**입니다. 작업 브랜치를 로컬에서 squash merge로 `develop`에 합치고 직접 push하며 Pull Request를 쓰지 않습니다.

스킬 본문과 기준 카탈로그는 영어로 씁니다. 반대로 스킬이 **만들어 내는 것**(보고서, 커밋 본문, 릴리즈 노트, README)은 그 저장소가 이미 쓰는 언어를 따릅니다.

## 문서

- [설치 가이드](docs/installation.md): CLI별 설치 위치, installer 옵션, 스킬 네임스페이스, 제거 방법입니다.
- [버전 판정 기준](docs/version-rubric.md): 설치된 프로젝트가 자기 기준으로 `patch`/`minor`/`major`를 가르는 방법과 `.spai/versioning.md` 파일 계약입니다.
- [프로젝트 유형별 기준 카탈로그](skills/version-rubric/rubrics/INDEX.md): 기준 초안 17종과 `rubric-scan`이 쓰는 탐지 신호표입니다. 영어로 쓰여 있습니다.
- [버전 정책](docs/versioning.md): SPAI 자신의 판정 기준 해설입니다. 규범 원본은 `.spai/versioning.md`입니다.
- [GitHub Repository Settings](docs/github-repository-settings.md): installer가 적용하는 GitHub 설정과, 선택 기능인 branch protection을 정하는 방식입니다.
- [Roadmap](docs/roadmap.md): SPAI의 정체성과 방향 후보(트리거 조건부) 기록입니다.

## 업데이트

- **Claude Code**: `/plugin marketplace update spai` 후 `/reload-plugins`.
- **Codex / Antigravity**: 설치 명령을 그대로 다시 실행합니다. installer는 멱등이라 바뀐 파일만 갱신하고 `.bak`으로 백업합니다.

에이전트 세션에서는 설치된 `spai-update` 스킬 하나가 전 과정을 처리합니다. 설치 상태와 최신 릴리즈를 비교하고, 사이 릴리즈 노트를 요약한 뒤, 각 target을 갱신하고 `github-sync`로 수렴합니다.

## 기여

<details>
<summary>dist 재생성과 검증</summary>

```bash
sh scripts/build-dist.sh      # skills/ 에서 dist/ 재생성
sh scripts/validate-dist.sh   # payload, marker, 기준 카탈로그 계약 검사
```

`dist/`는 `skills/` 하위 스킬들에서 생성됩니다. Claude Code 플러그인 payload는 `dist/claude-code-plugin/spai`이고, 마켓플레이스 정의는 `.claude-plugin/marketplace.json`입니다.

</details>

## License

MIT License
