# SPAI

**Scaffolded Procedures for AI Agents** — AI 에이전트 CLI 환경에 저장소 운영 절차를 설치하는 하네스 설정 도구입니다.

## 프로젝트 소개

사이드 프로젝트마다 AI 에이전트(Claude Code, Codex, Antigravity CLI)를 쓰다 보면, 브랜치 규칙·커밋 규칙·릴리즈 절차를 프로젝트마다·에이전트마다 다시 알려줘야 합니다. SPAI는 이 반복을 없앱니다: 같은 절차 스킬 세트를 어느 에이전트 환경에나 설치하고, 설치 이후의 업데이트와 상태 진단까지 관리합니다.

지원 대상: **Claude Code**(권장), **Codex**, **Antigravity CLI**

## 제공하는 가치

일반 스킬 모음과 달리 SPAI는 두 가지를 함께 관리합니다.

1. **저장소 상태 수렴** — 스킬(세션 절차)만 배포하는 게 아니라, 브랜치 모델·branch protection·릴리즈 규율이라는 *저장소 상태*를 `github-sync`로 맞추고 `spai-doctor`로 진단합니다. 규칙 문서가 아니라 집행되는 규칙입니다.
2. **에이전트 횡단 일관성 + 수명주기** — 하나의 절차 원본(`skills/`)을 여러 CLI 형식으로 렌더링해 배포하고, `spai-update`·`spai-doctor`로 설치 이후를 관리합니다. 각 CLI에는 그 CLI의 네이티브 배포 방식을 씁니다: Claude Code는 플러그인, Codex/Antigravity는 `spai-` prefix 파일입니다.

제공 스킬:

| 스킬 | 역할 |
|---|---|
| `develop-task-flow` | `feature/fix/chore` 브랜치에서 작업 후 `develop`에 squash merge |
| `github-release` | `develop`을 `main`으로 fast-forward 승격, 버전 계산 후 태그·릴리즈 생성 |
| `github-sync` | `main`/`develop` 브랜치·branch protection 동기화, 로컬 `pre-push` 가드 설치 |
| `project-setup` | SPAI 설치 후 저장소별 GitHub CLI 프로필 설정·검증 |
| `spai-update` | 설치본을 최신 SPAI 릴리즈로 업데이트 |
| `spai-doctor` | 설치 상태 진단(버전·드리프트·보호 규칙·레거시), read-only |
| `readme` | 프로젝트 타입 판정 후 `README.md` 생성, 기존 README는 코드와 대조해 드리프트 수정 |
| `version-rubric` | 프로젝트의 버전 판정 기준(`patch`/`minor`/`major`)을 `.spai/versioning.md`에 정하고 언제든 다시 설정. 유형별 기준 카탈로그를 함께 배포 |
| `rubric-scan` | 저장소를 스캔해 프로젝트 유형을 판정하고 카탈로그에서 맞는 버전 기준을 추천, read-only |

스킬 본문과 기준 카탈로그는 영어로 씁니다. 어느 언어권 저장소에 설치해도 같은 문서를 읽기 때문입니다. 반대로 스킬이 **만들어 내는 것**(보고서, 커밋 본문, 릴리즈 노트, README)은 그 저장소가 이미 쓰는 언어를 따르고, 판단할 근거가 없을 때만 영어로 씁니다.

작업 병합 방식은 **solo-cli 하나**입니다: 작업 브랜치를 로컬에서 `git merge --squash`로 `develop`에 합치고 직접 push하며, Pull Request를 쓰지 않습니다. 팀 단위 PR 흐름은 [Roadmap](docs/roadmap.md)의 보류 후보입니다.

## 문서

- [설치 가이드](docs/installation.md): CLI별로 무엇이 어디에 설치되고, 이후 어떻게 관리·제거되는지 설명합니다.
- [버전 판정 기준](docs/version-rubric.md): 설치된 프로젝트가 자기 기준으로 `patch`/`minor`/`major`를 가르는 방법, `.spai/versioning.md` 파일 계약과 설정값입니다.
- [프로젝트 유형별 기준 카탈로그](skills/version-rubric/rubrics/INDEX.md): API 서버·클라이언트·라이브러리·CLI·워커·인프라부터 문서 관리·콘텐츠·디자인 자산·데이터셋·설정 모음·교육 자료까지 17종의 기준 초안과, `rubric-scan`이 쓰는 탐지 신호표입니다.
- [버전 정책](docs/versioning.md): SPAI 자신의 판정 기준 해설입니다. 규범 원본은 `.spai/versioning.md`입니다.
- [GitHub Repository Settings](docs/github-repository-settings.md): installer가 project scope에서 적용하는 GitHub 설정과, 수동으로 안내하는 branch protection입니다.
- [Roadmap](docs/roadmap.md): SPAI의 정체성과 방향 후보(트리거 조건부) 기록입니다.

## 설치 방법

CLI마다 설치 방식이 다릅니다. **쓰는 CLI 하나만 골라 실행하세요.** 각 방식이 무엇을 설치하는지는 [설치 가이드](docs/installation.md)에 있습니다.

### Claude Code (권장)

SPAI를 가장 완전하게 지원하는 권장 경로입니다. 플러그인 호스트가 설치·업데이트·삭제를 관리하고, push 명령을 실행 전에 검사하는 `PreToolUse` 가드 hook은 Claude Code 플러그인에만 포함됩니다.

Claude Code 세션 안에서 실행합니다.

```text
/plugin marketplace add 0x0w1/spai
/plugin install spai@spai
```

### Codex

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target codex --scope project
```

### Antigravity CLI

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target antigravity --scope project
```

### Installer 주요 옵션

| 옵션 | 설명 |
|---|---|
| `--target codex\|antigravity` | 설치할 CLI 하나를 지정(필수) |
| `--scope project\|global` | 설치 범위 지정, 기본값은 `project` |
| `--github-profile <profile>` | 설치 중 GitHub 연동까지 할 때 프로필 지정(선택) |
| `--github-host <host>` | GitHub Enterprise 호스트 지정 |
| `--version vX.Y.Z` | 특정 SPAI 릴리즈로 설치·롤백 |
| `--skills a,b,c` | manifest에서 선택한 스킬만 설치 |
| `--configure-git-user` | 로컬 `user.name`·`user.email` 설정 |
| `--dry-run` | 파일을 변경하지 않고 예정 작업 확인 |
| `--force` | SPAI marker가 없는 기존 managed 파일 전체 교체 |

### 설치 후

스킬 설치에는 GitHub 프로필이 필요하지 않습니다. 설치가 끝난 뒤 `project-setup` 스킬을 실행하면 저장소별 GitHub 프로필을 설정하고, 버전 판정 기준을 정하고, `github-sync`와 `spai-doctor`까지 이어서 실행합니다. Claude Code는 `/spai:project-setup`, Codex/Antigravity는 `spai-project-setup`입니다.

버전 판정 기준은 프로젝트마다 다릅니다. `project-setup`이 기본 기준을 보여주고 그대로 쓸지만 물으며, 결과는 `.spai/versioning.md`에 기록됩니다. 나중에 언제든 `version-rubric` 스킬로 다시 정할 수 있습니다. 자세한 내용은 [버전 판정 기준](docs/version-rubric.md)에 있습니다.

프로필은 토큰이 아니라 로그인 이름만 저장합니다. `SPAI_GITHUB_PROFILE`이 있으면 세션 override로 사용하고, 없으면 `git config --local spai.githubProfile your-account`에 저장합니다. 이후 SPAI 스킬은 해당 프로필의 `gh` 보안 저장소 credential을 명령별로 사용하므로 전역 active account를 바꾸지 않습니다.

## 스킬 소유권과 이름 충돌

SPAI가 설치하는 스킬은 **사용자가 직접 만든 커스텀 스킬과 독립적으로 관리**됩니다. 방식은 대상 CLI에 따라 다릅니다.

**Claude Code — 플러그인 네임스페이스**

스킬 파일이 `.claude/skills/`에 복사되지 않습니다. Claude Code가 플러그인 스킬에 자동으로 네임스페이스를 붙여 `/spai:github-release`로 노출하므로, 사용자가 만든 `/github-release`와 **이름이 같아도 양쪽 모두 그대로 남습니다.** 설치·업데이트·삭제는 호스트가 담당합니다.

**Codex / Antigravity — 이름 prefix**

두 CLI에는 플러그인 시스템이 없어서 파일을 복사합니다. 대신 모든 SPAI 스킬 디렉토리와 frontmatter `name`에 `spai-` prefix를 붙입니다.

```text
.agents/skills/spai-github-sync/SKILL.md
.agents/skills/spai-github-release/SKILL.md
.agents/skills/spai-develop-task-flow/SKILL.md
.agents/skills/spai-project-setup/SKILL.md
.agents/skills/spai-update/SKILL.md
.agents/skills/spai-doctor/SKILL.md
.agents/skills/spai-readme/SKILL.md
```

**예약 이름** — SPAI는 `spai` 플러그인 이름과 `spai-` 로 시작하는 스킬 이름만 점유합니다. 커스텀 스킬에 `spai-` prefix만 쓰지 않으면 충돌하지 않습니다.

**managed block** — `AGENTS.md`/`GEMINI.md`의 SPAI 블록은 marker 사이 구간만 SPAI가 소유하며, 실제로 설치된 스킬만 안내합니다. 블록 바깥의 사용자 내용은 그대로 보존됩니다. Claude Code는 규칙 파일을 아예 건드리지 않습니다.

## 업데이트

- **Claude Code**: `/plugin marketplace update spai` 후 `/reload-plugins`. 마켓플레이스 auto-update로도 갱신됩니다.
- **Codex / Antigravity**: 설치 명령을 그대로 다시 실행합니다. installer는 멱등이라 변경된 파일만 갱신하고(`.bak` 백업), managed block은 marker 구간만 교체합니다.

이어서 `github-sync`로 저장소 설정을 수렴합니다. 이 수렴은 멱등이라 여러 버전을 건너뛰어도 한 번 실행으로 따라잡습니다.

AI Agent 환경에서는 설치된 `spai-update` 스킬 하나로 전 과정을 처리할 수 있습니다: 설치 상태와 최신 릴리즈를 비교하고, 사이 릴리즈 노트(특히 `### Migration` 섹션)를 요약한 뒤, 각 target을 갱신하고 `github-sync`로 수렴합니다.

## 개발자용: dist 재생성

```bash
sh scripts/build-dist.sh
```

`dist/`는 `skills/` 하위 스킬들에서 재생성됩니다. Claude Code 플러그인 payload는 `dist/claude-code-plugin/spai`이고, 마켓플레이스 정의는 `.claude-plugin/marketplace.json`입니다.

## 개발자용: dist 검증

```bash
sh scripts/validate-dist.sh
```

검증은 필수 dist 파일 존재 여부, managed block marker, SPAI 문자열, 금지 문자열을 확인합니다.

## 주의사항

- `install.sh`의 `--target`은 **필수이고 한 번에 하나**입니다. `all`은 지원하지 않고, `claude-code`도 target이 아닙니다.
- installer는 Codex와 Antigravity 전용입니다. Claude Code는 플러그인 호스트가 설치·업데이트·삭제를 전담합니다.
- 설치 스크립트는 기본 설치 중에는 로컬 git user 변경 prompt를 띄우지 않습니다. `gh` 로그인이 필요하거나 `--configure-git-user`를 사용하면 터미널 입력이 필요할 수 있습니다.
- 기존 파일을 변경해야 할 때는 `.bak` 백업을 생성합니다. `--dry-run`으로 변경 없이 예정 작업만 확인할 수 있습니다.
- project scope도 GitHub 프로필 없이 먼저 설치할 수 있습니다. 설치 중 GitHub 연동까지 하려면 `--github-profile <profile>`, `SPAI_GITHUB_PROFILE=<profile>`, 또는 로컬 `spai.githubProfile`을 사용하며, 기존 `--github-account`와 `SPAI_GITHUB_ACCOUNT`도 호환됩니다.
- `.git` repository가 없으면 GitHub Repository 설정 동기화를 건너뛰고 통과 로그를 출력합니다.
- 이전 버전이 설치한 `.github/PULL_REQUEST_TEMPLATE.md`, `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, 그리고 릴리즈 라벨 6종은 더 이상 사용하지 않습니다. 정리는 `github-sync` 스킬이 확인 후 안내합니다.

## License

MIT License
