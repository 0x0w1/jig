# SPAI

**Scaffolded Procedures for AI Agents** — AI 에이전트 CLI 환경에 저장소 운영 절차를 설치하는 하네스 설정 도구입니다.

## 프로젝트 소개

사이드 프로젝트마다 AI 에이전트(Claude Code, Codex, Antigravity CLI)를 쓰다 보면, 브랜치 규칙·커밋 규칙·릴리즈 절차를 프로젝트마다·에이전트마다 다시 알려줘야 합니다. SPAI는 이 반복을 없앱니다: 원라이너 한 번으로 같은 절차 스킬 세트를 어느 에이전트 환경에나 설치하고, 설치 이후의 업데이트와 상태 진단까지 관리합니다.

지원 대상: **Claude Code**, **Codex**, **Antigravity CLI**

## 제공하는 가치

일반 스킬 모음과 달리 SPAI는 두 가지를 함께 관리합니다.

1. **저장소 상태 수렴** — 스킬(세션 절차)만 배포하는 게 아니라, 브랜치 모델·branch protection·릴리즈 규율이라는 *저장소 상태*를 `github-sync`로 맞추고 `spai-doctor`로 진단합니다. 규칙 문서가 아니라 집행되는 규칙입니다.
2. **에이전트 횡단 일관성 + 수명주기** — 하나의 절차 원본(`skills/`)을 여러 CLI 형식으로 렌더링해 배포하고, 버전 스탬프·`spai-update`·`spai-doctor`로 설치 이후를 관리합니다. 스킬 선택 설치(`manifest.tsv` 카탈로그)를 지원합니다.

제공 스킬:

| 스킬 | 역할 |
|---|---|
| `develop-task-flow` | `feature/fix/chore` 브랜치에서 작업 후 `develop`에 squash merge |
| `github-release` | `develop`을 `main`으로 fast-forward 승격, 버전 계산 후 태그·릴리즈 생성 |
| `github-sync` | `main`/`develop` 브랜치와 branch protection 동기화 |
| `spai-update` | 설치본을 최신 SPAI 릴리즈로 업데이트 |
| `spai-doctor` | 설치 상태 진단(버전·드리프트·보호 규칙·레거시), read-only |

## 문서

- [GitHub Repository Settings](docs/github-repository-settings.md): `install.sh`가 project scope에서 적용하는 `develop` 브랜치 생성과 GitHub 설정, 그리고 수동으로 안내하는 branch protection입니다.
- [Roadmap](docs/roadmap.md): SPAI의 정체성과 방향 후보(트리거 조건부) 기록입니다.

## 설치 방법

공통 형식은 하나이고, `--target`만 바꾸면 됩니다. 필요하면 `--skills`로 설치할 스킬 구성을 고를 수 있습니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target <target> --scope project --github-account <account> [--skills a,b]
```

작업 병합 방식은 **solo-cli 하나**입니다: 작업 브랜치를 로컬에서 `git merge --squash`로 `develop`에 합치고 직접 push하며, Pull Request를 쓰지 않습니다. 팀 단위 PR 흐름은 [Roadmap](docs/roadmap.md)의 보류 후보입니다.

`--skills`를 생략하면 기본 스킬 전부가 설치됩니다. 스킬 목록은 `manifest.tsv`가 원본입니다.

### CLI 설치 방법

#### Claude Code

installer 방식 (`CLAUDE.md`, `.claude/skills/*`):

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target claude-code --scope project --github-account 0x0w1
```

플러그인 마켓플레이스 방식 (Claude Code 세션 안에서):

```text
/plugin marketplace add 0x0w1/spai
/plugin install spai@spai
```

두 방식의 차이:

- **installer**: 파일을 프로젝트에 복사(`CLAUDE.md` 규칙 + `.claude/skills/*` + 버전 스탬프). 업데이트는 재실행 또는 `spai-update`.
- **플러그인**: 파일 복사 없이 세션에 스킬 로드(`spai:github-release`처럼 네임스페이스 호출). workflow 스킬 3종(`github-sync`, `github-release`, `develop-task-flow`)만 포함하고, 업데이트는 `/plugin update spai@spai`. 스탬프·`spai-update`·`spai-doctor`는 installer 방식 전용.

#### Codex

`AGENTS.md`, `.agents/skills/*`에 설치합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target codex --scope project --github-account 0x0w1
```

#### Antigravity CLI

`GEMINI.md`, `.agents/skills/*`에 설치합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target antigravity --scope project --github-account 0x0w1
```

Antigravity는 워크스페이스 루트 `GEMINI.md`를 규칙 파일로 읽고, `.agents/skills/*`에서 네이티브 스킬을 인식합니다. global scope는 `~/.gemini/GEMINI.md`와 `~/.gemini/config/skills/*`에 설치합니다.

### 전체 설치

지원하는 모든 target을 한 번에 설치합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project --github-account 0x0w1
```

## 버전 해석과 고정 설치

installer는 기본적으로 최신 GitHub 릴리즈 태그를 조회해 해당 태그에 고정된 payload를 설치합니다. 조회에 실패하면 `main` 브랜치로 폴백합니다.

- 특정 버전 고정·롤백: `--version vX.Y.Z` 또는 `SPAI_VERSION=vX.Y.Z`

  ```bash
  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target all --scope project --github-account 0x0w1 --version v0.1.0
  ```

- `REPO_RAW_URL`을 직접 지정하면 버전 해석을 건너뛰고 그 URL을 그대로 사용합니다.
- 설치된 버전·스킬 구성은 `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`의 SPAI managed block 안에 `<!-- spai:version vX.Y.Z flow=solo-cli skills=<a,b,c> -->`로 스탬프됩니다. `spai-update`가 이 스탬프를 읽어 같은 구성으로 업데이트하고, `spai-doctor`가 진단 기준으로 사용합니다.

## 업데이트

Claude Code 플러그인 방식으로 설치했다면 `/plugin update spai@spai` 하나로 끝납니다. 아래는 installer 방식 기준입니다.

설치된 프로젝트의 업데이트는 두 단계입니다.

1. **파일 업데이트**: 설치 원라이너를 다시 실행합니다. installer는 멱등이므로 변경된 파일만 갱신하고(`.bak` 백업), managed block은 marker 구간만 교체합니다.

   ```bash
   curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
     | sh -s -- --target all --scope project --github-account 0x0w1
   ```

2. **저장소 설정 수렴**: 설치된 `github-sync` 스킬을 실행해 branch protection을 현재 모델에 맞추고, 레거시 release-drafter 파일·라벨을 확인 후 정리합니다. 이 수렴은 멱등이라 여러 버전을 건너뛰어도 한 번 실행으로 따라잡습니다.

AI Agent 환경에서는 설치된 `spai-update` 스킬 하나로 두 단계를 처리할 수 있습니다: 설치본 스탬프와 최신 릴리즈를 비교하고, 사이 릴리즈 노트(특히 `### Migration` 섹션)를 요약한 뒤, 최신 태그에 고정해 installer를 재실행하고 `github-sync`로 수렴합니다.

## 설치되는 파일 구조

### 공통 동작

installer는 각 설치 작업 전에 현재 상태를 먼저 검토합니다. 파일, managed block, `.env`, 로컬 git user, GitHub 설정이 이미 원하는 상태이면 `PASS` 로그를 출력하고 쓰기 작업을 건너뜁니다. `--configure-git-user`도 기존 값이 유효하면 입력을 묻지 않고, 빠져 있거나 유효하지 않은 값만 입력받습니다.

GitHub 작업 전에 installer는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 계정이 `gh`에 로그인되어 있는지 확인합니다. 없으면 `gh auth login`을 실행한 뒤 `gh auth switch --user`로 active account를 맞추고 검증합니다. `.git` repository가 없으면 GitHub 작업은 건너뛰고 통과 로그를 출력합니다.

로컬 git 작성자 정보를 바꾸고 싶으면 다음처럼 실행할 수 있습니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 --configure-git-user
```

비대화식으로 설정하려면 값을 직접 넘깁니다.

```bash
sh install.sh --target all --scope project --github-account your-account \
  --git-user-name "Your Name" --git-user-email "your@email.com"
```

project scope 설치 시 `gh`를 사용할 수 있으면 GitHub Repository 설정도 동기화합니다. branch protection은 설치하지 않고, 종료 시 `GUIDE`로 수동 작업만 안내합니다.

```text
Repository context:
  visibility and viewer permission: checked with gh repo view

Branches:
  develop:
    created from main when missing
```

`install.sh`는 branch protection을 직접 적용하지 않습니다. `main`과 `develop`에 force push와 branch deletion을 금지하는 보호 규칙을 설정하고, Pull Request는 필수로 하지 마세요. 설치된 `github-sync` 스킬이 이 보호 규칙 적용을 대신 수행할 수 있습니다.

자세한 적용/건너뛰기 조건은 [GitHub Repository Settings](docs/github-repository-settings.md)를 참고하세요.

### Codex

project scope:

```text
./AGENTS.md
.agents/
  skills/
    github-sync/
      SKILL.md
    github-release/
      SKILL.md
    develop-task-flow/
      SKILL.md
    spai-update/
      SKILL.md
    spai-doctor/
      SKILL.md
```

global scope:

```text
~/.codex/AGENTS.md
~/.agents/skills/
  github-sync/
    SKILL.md
  github-release/
    SKILL.md
  develop-task-flow/
    SKILL.md
  spai-update/
    SKILL.md
  spai-doctor/
    SKILL.md
```

Codex는 repo/user skill 위치에 절차형 `SKILL.md`를 설치합니다. `AGENTS.md`에 이미 SPAI marker가 있으면 해당 managed block만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 뒤에 추가합니다. 기존 파일 전체를 SPAI 템플릿으로 교체하려면 `--force`를 사용합니다.

### Claude Code

project scope:

```text
./CLAUDE.md
.claude/
  skills/
    github-sync/
      SKILL.md
    github-release/
      SKILL.md
    develop-task-flow/
      SKILL.md
    spai-update/
      SKILL.md
    spai-doctor/
      SKILL.md
```

global scope:

```text
~/.claude/CLAUDE.md
~/.claude/skills/
  github-sync/
    SKILL.md
  github-release/
    SKILL.md
  develop-task-flow/
    SKILL.md
  spai-update/
    SKILL.md
  spai-doctor/
    SKILL.md
```

Claude Code는 project/user skill을 `.claude/skills/<skill>/SKILL.md` 구조로 설치합니다. `CLAUDE.md`에 이미 SPAI marker가 있으면 해당 managed block만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 뒤에 추가합니다. 기존 파일 전체를 SPAI 템플릿으로 교체하려면 `--force`를 사용합니다.

### Antigravity CLI

project scope:

```text
./GEMINI.md
.agents/
  skills/
    github-sync/
      SKILL.md
    github-release/
      SKILL.md
    develop-task-flow/
      SKILL.md
    spai-update/
      SKILL.md
    spai-doctor/
      SKILL.md
```

global scope:

```text
~/.gemini/GEMINI.md
~/.gemini/config/skills/
  github-sync/
    SKILL.md
  github-release/
    SKILL.md
  develop-task-flow/
    SKILL.md
  spai-update/
    SKILL.md
  spai-doctor/
    SKILL.md
```

Antigravity CLI는 워크스페이스 루트 `GEMINI.md`를 규칙 파일로 읽고 `.agents/skills/<skill>/SKILL.md`에서 네이티브 스킬을 인식합니다. Codex와 Antigravity는 project scope에서 동일한 `.agents/skills/` 경로를 공유하므로 두 target을 함께 설치해도 안전합니다. `GEMINI.md`에 이미 SPAI marker가 있으면 해당 managed block만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 뒤에 추가합니다. 기존 파일 전체를 SPAI 템플릿으로 교체하려면 `--force`를 사용합니다.

## 스킬 소유권과 이름 충돌

SPAI가 설치하는 스킬은 **사용자가 직접 만든 커스텀 스킬과 독립적으로 관리**됩니다.

**예약 이름** — SPAI는 아래 이름을 점유합니다. 커스텀 스킬에는 다른 이름을 쓰세요.

`github-sync`, `github-release`, `develop-task-flow`, `spai-update`, `spai-doctor`

**소유권 마커** — 배포되는 모든 스킬 payload는 frontmatter 바로 아래에 `<!-- spai:owned skill=<name> -->` 마커를 담고 있습니다. installer와 `spai-doctor`는 이 마커로 "SPAI가 설치한 파일"과 "사용자 파일"을 구분합니다.

**충돌 처리** — 설치 대상 경로에 마커 없는 파일이 이미 있으면 installer는 **덮어쓰지 않고 건너뜁니다**. 경고와 함께 `Skipped skill files not managed by SPAI` 목록으로 보고하고, `GUIDE`에서 선택지를 안내합니다. 이름을 SPAI에 넘기려면 `--force`로 재실행하세요(기존 파일은 `.bak`로 백업됩니다).

```text
SPAI [warn] Skill conflict: .claude/skills/github-release/SKILL.md exists and is not managed by SPAI.
            Skipping it to preserve your file; use --force to replace it.
```

**기존 설치본 승계** — 마커가 도입되기 전에 설치된 파일은 managed block의 `<!-- spai:version ... skills=... -->` 스탬프를 소유권 대장으로 삼아 자동으로 승계됩니다. 따라서 기존 사용자의 업데이트는 그대로 동작합니다.

**고아 파일** — `--skills`에서 빠진 스킬의 파일이 디스크에 남아 있으면 `Orphan skill files from a previous SPAI selection`으로 보고합니다. installer는 **어떤 경우에도 스킬 파일을 삭제하지 않습니다**. 직접 지우거나, 다시 `--skills`에 넣어 관리 대상으로 되돌리세요.

**managed block** — `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`의 SPAI 블록은 실제로 설치된 스킬만 안내합니다. `--skills`로 일부만 설치하면 나머지 스킬 항목은 블록에서 제외됩니다. 블록 바깥의 사용자 내용은 그대로 보존됩니다.

## 개발자용: dist 재생성

```bash
sh scripts/build-dist.sh
```

`dist/`는 `skills/` 하위 스킬들에서 재생성됩니다.

## 개발자용: dist 검증

```bash
sh scripts/validate-dist.sh
```

검증은 필수 dist 파일 존재 여부, managed block marker, SPAI 문자열, 금지 문자열을 확인합니다.

## 주의사항

- 설치 스크립트는 기본 설치 중에는 로컬 git user 변경 prompt를 띄우지 않습니다. `gh` 로그인이 필요하거나 `--configure-git-user`를 사용하면 터미널 입력이 필요할 수 있습니다.
- 설치 스크립트는 재실행 시 이미 반영된 작업을 `PASS` 처리하고, 필요한 작업만 입력받거나 실행합니다.
- 기존 파일을 변경해야 할 때는 `.bak` 백업을 생성합니다.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`처럼 managed block을 쓰는 파일은 marker가 있으면 그 구간만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 추가합니다. 전체 템플릿으로 교체하려면 `--force`를 사용합니다.
- 설치 대상 경로에 SPAI 소유권 마커가 없는 스킬 파일이 있으면 건너뛰고 보고합니다. 덮어쓰려면 `--force`가 필요합니다.
- `--skills`에서 제외된 스킬 파일은 고아로 보고만 하며 삭제하지 않습니다.
- `--dry-run`을 사용하면 실제 파일 시스템을 수정하지 않고 예정 작업을 출력하며, 파일과 managed block은 현재 내용과 비교해 missing/changed/PASS 상태를 구분합니다.
- project scope 설치는 `--github-account <account>` 또는 `SPAI_GITHUB_ACCOUNT=<account>` 입력이 필요합니다.
- `.git` repository가 없으면 GitHub Repository 설정 동기화를 건너뛰고 통과 로그를 출력합니다.
- 원격 `develop` 브랜치가 없으면 `main`의 현재 commit에서 `develop`을 만듭니다.
- 이전 버전이 설치한 `.github/PULL_REQUEST_TEMPLATE.md`, `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, 그리고 릴리즈 라벨 6종은 더 이상 사용하지 않습니다. 정리는 `github-sync` 스킬이 확인 후 안내합니다.

## License

MIT License
