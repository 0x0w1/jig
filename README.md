# SPAI

## 문서

- [GitHub Repository Settings](docs/github-repository-settings.md): `install.sh`가 project scope에서 적용하는 라벨 정리, `develop` 브랜치 생성, branch protection, General 설정입니다.

## 개요

SPAI는 Scaffolded Procedures for AI Agents의 약자입니다.

SPAI는 Codex, Claude Code, Cursor, Gemini CLI, OpenCode 등 여러 AI Agent 환경에서 사용할 수 있는 절차형 스킬을 배포하기 위한 오픈소스 프로젝트입니다.

이 프로젝트는 `curl` 또는 `wget`을 통해 각 Agent 환경에 맞는 스킬/규칙 파일을 설치할 수 있도록 구성되어 있습니다.

> 이 설치 스크립트는 AI Agent용 스킬/규칙 파일과 Release Drafter YAML 파일을 설치하고, project scope에서는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 `gh` 계정을 사용합니다. `gh`를 사용할 수 있으면 표준 6개 GitHub 라벨만 남도록 라벨을 정리하며, `develop` 브랜치 생성, `main`/`develop` classic branch protection, General의 Automatically delete head branches 설정을 동기화합니다. 표준 6개 외 라벨은 삭제됩니다. 브랜치 수동 삭제, 릴리스, 태그, PR 생성/병합은 직접 수행하지 않습니다.

## SPAI의 의미

`SPAI`는 `Scaffolded Procedures for AI Agents`를 의미합니다.

반복 가능한 Repository 운영 절차를 여러 AI Agent가 읽을 수 있는 형태로 scaffold하고 배포하는 것을 목표로 합니다.

## 지원 대상

- Codex
- Claude Code
- Cursor
- Gemini CLI
- OpenCode

## 설치 방법

### Codex

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target codex --scope project --github-account 0x0w1
```

### Claude Code

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target claude-code --scope project --github-account 0x0w1
```

### Cursor

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target cursor --scope project --github-account 0x0w1
```

Cursor는 현재 project scope 설치만 지원합니다.

### Gemini CLI

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target gemini-cli --scope project --github-account 0x0w1
```

### OpenCode

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target opencode --scope project --github-account 0x0w1
```

### 전체 설치

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project --github-account 0x0w1
```

## wget 사용 예시

```bash
wget -qO- https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project --github-account 0x0w1
```

## curl 사용 예시

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project --github-account 0x0w1
```

보안상 스크립트를 먼저 확인한 뒤 실행하는 방식을 권장합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh -o install.sh
less install.sh
sh install.sh --target all --scope project --github-account 0x0w1
```

Fork나 로컬 테스트에서는 `REPO_RAW_URL`을 바꿀 수 있습니다.

```bash
REPO_RAW_URL="https://raw.githubusercontent.com/my-org/spai/main" sh install.sh
```

## 설치되는 파일 구조

### 공통 project 파일

project scope 설치 시 target과 관계없이 다음 파일도 설치됩니다.

```text
.github/
  drafter-config.yaml
  workflows/
    drafter.yaml
```

project scope 설치 시 `gh`를 사용할 수 있으면 다음 표준 라벨을 생성하거나 업데이트하고, 이 목록에 없는 기존 라벨은 삭제합니다.

```text
patch
minor
major
enhancement
fix
chore
```

라벨 정리 전에 installer는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 계정을 `gh auth switch --user`로 선택하고 GitHub CLI 설정을 확인합니다. `.git` repository가 없으면 라벨 정리는 건너뛰고 통과 로그를 출력합니다.

project scope 설치 시 `gh`를 사용할 수 있으면 GitHub Repository 설정도 동기화합니다.

```text
General:
  Automatically delete head branches: enabled

Branches:
  develop:
    created from main when missing

Classic branch protection:
  main:
    pull request required
    required status checks off
    linear history not required
    force push disabled
    branch deletion disabled
    conversation resolution required
  develop:
    pull request required
    required status checks off
    force push disabled
    branch deletion disabled
    conversation resolution required
```

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
```

Codex는 repo/user skill 위치에 세 개의 `SKILL.md`를 설치하고, `AGENTS.md`에는 SPAI managed block을 삽입하거나 교체합니다.

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
```

Claude Code는 세 개의 project/user skill을 `.claude/skills/<skill>/SKILL.md` 구조로 설치하고, `CLAUDE.md`에는 SPAI managed block을 삽입하거나 교체합니다. 실제 Repository 설정 파일은 공통 project 파일로 `.github/`에 설치됩니다.

### Cursor

project scope:

```text
.cursor/
  rules/
    github-sync.mdc
    github-release.mdc
    develop-task-flow.mdc
```

Cursor global scope는 현재 지원하지 않습니다.

### Gemini CLI

project scope:

```text
./GEMINI.md
```

global scope:

```text
~/.gemini/GEMINI.md
```

### OpenCode

project scope:

```text
./AGENTS.md
```

global scope:

```text
~/.config/opencode/AGENTS.md
```

Codex와 OpenCode는 project scope에서 모두 `AGENTS.md`를 사용합니다. SPAI는 동일한 managed block marker를 사용해 중복 삽입을 방지합니다.

## 제공되는 스킬

현재 제공되는 절차형 스킬/룰은 세 개입니다.

- `github-sync`: Release Drafter 파일, 표준 라벨, `main`/`develop` 브랜치, 브랜치 보호를 동기화합니다. 릴리스 생성에는 사용하지 않습니다.
- `github-release`: `origin/develop`에서 `release/vX.Y.Z`를 만들고 `main` 릴리스 PR을 통해 Release Drafter 게시를 진행합니다.
- `develop-task-flow`: 일반 개발 작업을 `origin/develop`에서 feature/fix/chore 브랜치로 시작하고 테스트, PR, develop 머지까지 진행합니다.

SPAI는 각 Agent 환경의 권장 instruction surface에 맞춰 위 세 절차를 설치합니다.

## 스킬이 설정하는 GitHub Repository 정책

- 보호된 `main` 및 `develop` 브랜치
- `develop` 대상 작업 브랜치
  - `feature/<slug>`
  - `fix/<slug>`
  - `chore/<slug>`
- `main` 대상 릴리스 브랜치
  - `release/vX.Y.Z`
- 정확히 6개의 표준 라벨
  - `patch`
  - `minor`
  - `major`
  - `enhancement`
  - `fix`
  - `chore`
- Release Drafter 기반 릴리스 노트 및 태그 게시 설정
- 릴리스 PR은 `patch`, `minor`, `major` 버전 업그레이드로 처리
- Release Drafter 버전 계산을 위해 실제 변경 PR에도 `patch`, `minor`, `major` 중 하나의 version 라벨을 적용
- General의 Automatically delete head branches 설정

## Safety Rules

- force push를 하지 않습니다.
- 브랜치를 삭제하지 않습니다.
- 명시적 확인 없이 내용이 다른 파일을 덮어쓰지 않습니다.
- 설정 중에 릴리스나 태그를 생성하지 않습니다.
- 설정 중에 PR을 병합하지 않습니다.
- 사용자의 관련 없는 working tree 변경 사항을 수정하거나 되돌리지 않습니다.
- 일반 Agent 작업에서는 명시적 확인 없이 라벨을 삭제하지 않습니다. `install.sh --scope project`는 표준 6개 라벨만 남기도록 표준 외 라벨을 삭제하는 설치 동작을 포함합니다.
- `install.sh`는 표준 6개 라벨 정리, General의 Automatically delete head branches, `main`/`develop` branch protection 외의 GitHub Repository 설정을 직접 변경하지 않습니다.
- `install.sh`는 브랜치를 수동으로 삭제하지 않습니다.

## 개발자용: dist 재생성

```bash
sh scripts/build-dist.sh
```

`dist/`는 `skills/github-sync`, `skills/github-release`, `skills/develop-task-flow`, 그리고 `skills/github-release-setup/files/`에서 재생성됩니다.

## 개발자용: dist 검증

```bash
sh scripts/validate-dist.sh
```

검증은 필수 dist 파일 존재 여부, managed block marker, SPAI 문자열, 금지 문자열을 확인합니다.

## 주의사항

- 설치 스크립트는 자동화 친화적으로 동작하며 interactive prompt를 사용하지 않습니다.
- 기존 파일을 변경해야 할 때는 `.bak` 백업을 생성합니다.
- `--dry-run`을 사용하면 실제 파일 시스템을 수정하지 않고 예정 작업만 출력합니다.
- project scope 설치 시 `.github/drafter-config.yaml`과 `.github/workflows/drafter.yaml`도 설치됩니다.
- project scope 설치는 `--github-account <account>` 또는 `SPAI_GITHUB_ACCOUNT=<account>` 입력이 필요합니다.
- project scope 설치 시 `gh` 인증, git repository, GitHub repository 확인이 가능하면 지정한 `gh` 계정으로 표준 6개 라벨만 남도록 라벨을 정리하고, `develop` 브랜치 생성, branch protection, Automatically delete head branches 설정을 동기화하며 가능한 범위에서 검증합니다.
- `.git` repository가 없으면 GitHub Repository 설정 동기화를 건너뛰고 통과 로그를 출력합니다.
- 원격 `develop` 브랜치가 없으면 `main`의 현재 commit에서 `develop`을 만든 뒤 branch protection을 적용합니다.
- 표준 6개 외의 기존 라벨은 삭제됩니다.
- `content` 라벨은 표준 라벨이 아니며, 신규 기능 또는 개선 사항은 `enhancement`로 처리합니다.
- Release Drafter 실행 결과는 대상 Repository의 GitHub Actions 권한과 branch protection 설정에 영향을 받습니다.

## License

MIT License
