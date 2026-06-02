# SPAI

## 개요

SPAI는 Scaffolded Procedures for AI Agents의 약자입니다.

SPAI는 Codex, Claude Code, Cursor, Gemini CLI, OpenCode 등 여러 AI Agent 환경에서 사용할 수 있는 절차형 스킬을 배포하기 위한 오픈소스 프로젝트입니다.

이 프로젝트는 `curl` 또는 `wget`을 통해 각 Agent 환경에 맞는 스킬/규칙 파일을 설치할 수 있도록 구성되어 있습니다.

> 이 설치 스크립트는 AI Agent용 스킬/규칙 파일과 Release Drafter YAML 파일을 설치하고, `gh`를 사용할 수 있으면 표준 6개 GitHub 라벨을 생성하거나 업데이트합니다. 라벨 삭제, 브랜치 보호, 릴리스, 태그, PR 병합은 직접 수행하지 않습니다. 그 외 Repository 설정 변경은 설치된 스킬을 Agent가 실행할 때 사용자의 확인과 권한 범위 안에서 수행됩니다.

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
  | sh -s -- --target codex --scope project
```

### Claude Code

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target claude-code --scope project
```

### Cursor

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target cursor --scope project
```

Cursor는 현재 project scope 설치만 지원합니다.

### Gemini CLI

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target gemini-cli --scope project
```

### OpenCode

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target opencode --scope project
```

### 전체 설치

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project
```

## wget 사용 예시

```bash
wget -qO- https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project
```

## curl 사용 예시

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
  | sh -s -- --target all --scope project
```

보안상 스크립트를 먼저 확인한 뒤 실행하는 방식을 권장합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh -o install.sh
less install.sh
sh install.sh --target all --scope project
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

project scope 설치 시 `gh`를 사용할 수 있으면 다음 표준 라벨도 생성하거나 업데이트합니다.

```text
patch
minor
major
enhancement
fix
chore
```

### Codex

project scope:

```text
./AGENTS.md
```

global scope:

```text
~/.codex/AGENTS.md
```

Codex는 `AGENTS.md`에 SPAI managed block을 삽입하거나 교체합니다.

### Claude Code

project scope:

```text
.claude/skills/github-release-setup/
  SKILL.md
  files/
    drafter-config.yaml
    drafter.yaml
```

global scope:

```text
~/.claude/skills/github-release-setup/
  SKILL.md
  files/
    drafter-config.yaml
    drafter.yaml
```

Claude Code는 스킬 디렉터리에도 drafter YAML을 bundled files로 함께 설치합니다. 실제 Repository 설정 파일은 공통 project 파일로 `.github/`에 설치됩니다.

### Cursor

project scope:

```text
.cursor/rules/github-release-setup.mdc
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

현재 제공되는 스킬은 `GitHub Release Setup Skill`입니다.

이 스킬은 대상 Repository에 GitHub Release Drafter, 표준 라벨, `main`/`develop` 브랜치 보호, 릴리스 브랜치 정책을 안전하게 적용하도록 Agent에게 절차를 제공합니다.

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

## Safety Rules

- force push를 하지 않습니다.
- 브랜치를 삭제하지 않습니다.
- 명시적 확인 없이 라벨을 삭제하지 않습니다.
- 명시적 확인 없이 내용이 다른 파일을 덮어쓰지 않습니다.
- 설정 중에 릴리스나 태그를 생성하지 않습니다.
- 설정 중에 PR을 병합하지 않습니다.
- 사용자의 관련 없는 working tree 변경 사항을 수정하거나 되돌리지 않습니다.
- `install.sh`는 표준 6개 라벨 생성/업데이트 외의 GitHub Repository 설정을 직접 변경하지 않습니다.

## 개발자용: dist 재생성

```bash
sh scripts/build-dist.sh
```

`dist/`는 `skills/github-release-setup/prompt.md`와 `skills/github-release-setup/files/`에서 재생성됩니다.

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
- project scope 설치 시 `gh` 인증과 repository 확인이 가능하면 표준 6개 라벨을 생성하거나 업데이트합니다.
- 표준 6개 외의 기존 라벨은 삭제하지 않습니다.
- `content` 라벨은 표준 라벨이 아니며, 신규 기능 또는 개선 사항은 `enhancement`로 처리합니다.
- Release Drafter 실행 결과는 대상 Repository의 GitHub Actions 권한과 branch protection 설정에 영향을 받습니다.

## License

MIT License
