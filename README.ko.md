# jig

<p align="center">
  <img src="docs/assets/jig-logo.png" width="160" alt="jig 프로젝트 로고: 두 가이드가 서로 다른 입력을 하나의 반복 가능한 결과로 정렬합니다">
</p>

**같은 자리에서, 매번 같게** — 지그는 작업물을 잡아 매번 같은 자리에서 잘리게 합니다. 이 지그는 저장소 운영 절차를 잡아, 어느 프로젝트에서 어느 AI 에이전트 CLI를 쓰든 같은 절차가 돌게 합니다.

[English](README.md)

[빠른 시작](#빠른-시작) · [스킬](#스킬) · [문서](#문서) · [업데이트](#업데이트) · [License](#license)

## 프로젝트 소개

![jig 프로젝트 소개: 세 에이전트 작업 흐름이 공통 가이드를 통과해 하나의 일관된 결과가 됩니다](docs/assets/jig-project-hero-convergence.png)

사이드 프로젝트마다 AI 에이전트(Claude Code, Codex, Antigravity CLI)를 쓰다 보면, 브랜치 규칙·커밋 규칙·릴리즈 절차를 프로젝트마다·에이전트마다 다시 알려줘야 합니다. jig는 이 반복을 없앱니다: 같은 절차 스킬 세트를 어느 에이전트 환경에나 설치하고 설치 이후의 업데이트와 상태 진단까지 관리합니다.

지원 대상: **Claude Code**(권장), **Codex**, **Antigravity CLI**

## 빠른 시작

![jig 빠른 시작: CLI 하나에 설치하고, project-setup으로 프로필·버전 기준·브랜치 수렴·점검을 끝낸 뒤, jig-doctor로 확인하고, 이후 작업은 develop-task-flow와 github-release로 흘러갑니다](docs/assets/quick-start.svg)

준비물: git 저장소, 그리고 Codex·Antigravity는 `curl` 또는 `wget`. GitHub 연동까지 하려면 `gh` 로그인이 필요하지만 스킬 설치 자체에는 필요 없습니다.

### 1. 설치 — 쓰는 CLI 하나만

**Claude Code**(권장) — 세션 안에서 실행합니다. 플러그인 호스트가 설치·업데이트·삭제를 관리하고, push 명령을 실행 전에 검사하는 `PreToolUse` 가드 hook은 여기에만 들어 있습니다.

```text
/plugin marketplace add 0x0w1/jig
/plugin install jig@jig
```

**Codex**와 **Antigravity CLI** — 저장소 루트에서 실행합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/jig/main/install.sh \
  | sh -s -- --target codex --scope project        # 또는 --target antigravity
```

옵션, 설치 위치, 스킬 네임스페이스, 제거는 [설치 가이드](docs/installation.ko.md)에 있습니다.

### 2. 저장소에 연결

에이전트 세션에서 `project-setup`을 실행합니다. Claude Code는 `/jig:project-setup`, Codex와 Antigravity는 `jig-project-setup`입니다.

한 번 실행으로 네 가지가 끝납니다.

1. 이 저장소가 쓸 GitHub 프로필 선택·검증 (전역 active 계정은 건드리지 않음)
2. 버전 판정 기준을 정해 `.jig/versioning.md`에 기록
3. `github-sync`로 `main`·`develop` 브랜치 수렴, branch protection은 물어보고 적용 (public 저장소는 무료, private은 유료 플랜에서만 가능한 선택 기능)
4. `jig-doctor`로 설치 상태 점검

### 3. 확인

`/jig:jig-doctor` (Codex·Antigravity는 `jig-doctor`)를 실행하면 설치 버전, 파일 드리프트, 브랜치 보호, GitHub 프로필, 기준 파일 상태를 read-only로 보고합니다. 고칠 것이 있으면 어느 스킬이 고치는지까지 알려줍니다.

이후로는 스킬 이름을 부르거나 하려는 일을 말하면 에이전트가 알아서 고릅니다.

## 스킬

jig는 일반 스킬 모음과 달리 세션 절차만 배포하지 않습니다. 브랜치 모델·branch protection·릴리즈 규율이라는 *저장소 상태*를 함께 수렴하고, 설치 이후를 `jig-update`와 `jig-doctor`로 관리합니다. 하나의 절차 원본(`skills/`)을 각 CLI의 네이티브 형식으로 렌더링합니다 — Claude Code는 플러그인, Codex와 Antigravity는 `jig-` prefix 파일입니다.

| 스킬 | 역할 |
|---|---|
| `develop-task-flow` | 작업 브랜치에서 작업 후 `develop`에 squash merge |
| `github-release` | `develop`을 `main`으로 승격, 태그와 릴리즈 발행 |
| `github-sync` | 브랜치 수렴, 선택적 보호 설정, 로컬 `pre-push` 가드 |
| `project-setup` | 저장소에 GitHub CLI 프로필 연결 |
| `jig-update` | 설치본을 최신 릴리즈로 갱신 |
| `jig-doctor` | 설치 상태 read-only 진단 |
| `readme` | README 생성, 기존 README는 코드와 대조해 수정 |
| `version-rubric` | `patch`/`minor`/`major` 기준을 `.jig/versioning.md`에 확정 |
| `rubric-scan` | 프로젝트 유형 판정 후 맞는 기준 추천 |

작업 병합 방식은 **solo-cli 하나**입니다. 작업 브랜치를 로컬에서 squash merge로 `develop`에 합치고 직접 push하며 Pull Request를 쓰지 않습니다.

스킬 본문과 기준 카탈로그는 영어로 씁니다. 반대로 스킬이 **만들어 내는 것**(보고서, 커밋 본문, 릴리즈 노트, README)은 그 저장소가 이미 쓰는 언어를 따릅니다.

## 문서

- [설치 가이드](docs/installation.ko.md): CLI별 설치 위치, installer 옵션, 스킬 네임스페이스, 제거 방법입니다.
- [버전 판정 기준](docs/version-rubric.ko.md): 설치된 프로젝트가 자기 기준으로 `patch`/`minor`/`major`를 가르는 방법과 `.jig/versioning.md` 파일 계약입니다.
- [프로젝트 유형별 기준 카탈로그](skills/version-rubric/rubrics/INDEX.md): 기준 초안 17종과 `rubric-scan`이 쓰는 탐지 신호표입니다. 영어로 쓰여 있습니다.
- [버전 정책](docs/versioning.ko.md): jig 자신의 판정 기준 해설입니다. 규범 원본은 `.jig/versioning.md`입니다.
- [GitHub Repository Settings](docs/github-repository-settings.ko.md): installer가 적용하는 GitHub 설정과, 선택 기능인 branch protection을 정하는 방식입니다.
- [Roadmap](docs/roadmap.ko.md): jig의 정체성과 방향 후보(트리거 조건부) 기록입니다.

## 업데이트

`jig-update` 스킬을 실행합니다. 설치 상태와 최신 릴리즈를 비교하고, 사이 릴리즈 노트를 요약한 뒤, 각 target을 갱신하고 `github-sync`로 저장소 설정까지 수렴합니다.

```text
/jig:jig-update
```

직접 하려면 각 CLI가 제공하는 방법을 씁니다. Claude Code는 플러그인 호스트가 업데이트를 담당합니다.

```text
/plugin marketplace update jig
/reload-plugins
```

Codex와 Antigravity는 설치 명령을 그대로 다시 실행합니다. installer는 멱등이라 바뀐 파일만 갱신하고 `.bak`으로 백업합니다.

### `spai`에서 넘어오는 경우

jig의 옛 이름은 `spai`였고, 저장소 슬러그도 `0x0w1/spai`에서 `0x0w1/jig`로 바뀌었습니다. GitHub가 옛 슬러그를 리다이렉트하므로 기존 설치본은 그대로 동작하고, 레거시 이름도 계속 인식합니다: `SPAI_*` 환경 변수, `spai.*` config 키, `.spai/versioning.md`, `<!-- spai:start ... -->` managed block, `# spai:pre-push` 가드입니다.

전환은 `jig-update`가 안내합니다. Claude Code는 플러그인 호스트가 플러그인 정체성을 소유하므로 이 부분만 직접 실행합니다.

```text
/plugin marketplace add 0x0w1/jig
/plugin install jig@jig
/plugin uninstall spai@spai
/reload-plugins
```

## License

MIT License
