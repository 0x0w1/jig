# SPAI

## 문서

- [GitHub Repository Settings](docs/github-repository-settings.md): `install.sh`가 project scope에서 적용하는 라벨 정리, `develop` 브랜치 생성, branch protection, General 설정입니다.

## 개요

SPAI는 Scaffolded Procedures for AI Agents의 약자입니다.

SPAI는 Codex, Claude Code, Cursor, Gemini CLI, OpenCode 등 여러 AI Agent 환경에서 사용할 수 있는 절차형 스킬을 배포하기 위한 오픈소스 프로젝트입니다.

이 프로젝트는 `curl` 또는 `wget`을 통해 각 Agent 환경에 맞는 스킬/규칙 파일을 설치할 수 있도록 구성되어 있습니다.

> 이 설치 스크립트는 AI Agent용 스킬/규칙/가드레일 파일과 Release Drafter YAML 파일을 설치하고, project scope에서는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 `gh` 계정을 사용합니다. 해당 `gh` 계정이 로그인되어 있지 않으면 `gh auth login`을 실행하고, 로그인되어 있으면 active account가 맞는지 검증합니다. `gh`를 사용할 수 있으면 표준 6개 GitHub 라벨만 남도록 라벨을 정리하며, repository visibility와 현재 계정 권한을 확인한 뒤 `develop` 브랜치 생성, `main`/`develop` classic branch protection, General의 Automatically delete head branches 설정, Actions workflow permissions의 read and write 설정을 동기화합니다. 표준 6개 외 라벨은 삭제됩니다. 브랜치 수동 삭제, 릴리스, 태그, PR 생성/병합은 직접 수행하지 않습니다.

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
  PULL_REQUEST_TEMPLATE.md
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

라벨 정리 전에 installer는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 계정이 `gh`에 로그인되어 있는지 확인합니다. 없으면 `gh auth login`을 실행한 뒤 `gh auth switch --user`로 active account를 맞추고 검증합니다. `.git` repository가 없으면 라벨 정리는 건너뛰고 통과 로그를 출력합니다.

installer는 각 설치 작업 전에 현재 상태를 먼저 검토합니다. 파일, managed block, `.env`, 로컬 git user, GitHub 라벨, repository settings, branch protection이 이미 원하는 상태이면 `PASS` 로그를 출력하고 쓰기 작업을 건너뜁니다. `--configure-git-user`와 `--configure-knowledges-root`도 기존 값이 유효하면 입력을 묻지 않고, 빠져 있거나 유효하지 않은 값만 입력받습니다.

설치되는 PR template은 `feature/*`, `fix/*`, `chore/*`에서 `develop`으로 보내는 PR의 `## Summary`, `## Details`, `## Tests`를 한글 개조식으로 작성하도록 안내합니다. 릴리스 생성 시 workflow는 `develop` 대상 PR 중 `enhancement`, `fix`, `chore` 라벨이 있는 PR의 `## Summary` bullet을 취합해 릴리즈 노트 하단 Summary에 추가합니다. `## Summary`에서는 파일명, 설정 키, 라벨, 브랜치명, workflow 이름처럼 강조할 기술 용어를 backtick으로 감쌉니다.

로컬 git 작성자 정보를 바꾸고 싶으면 다음처럼 실행할 수 있습니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 --configure-git-user
```

비대화식으로 설정하려면 값을 직접 넘깁니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 \
  --git-user-name "0x0w1" --git-user-email "rootsik1221@gmail.com"
```

knowledges raw ingest를 사용할 프로젝트에서는 `install.sh`에 cloned knowledges repository의 절대경로를 넘겨 `.env`를 설정할 수 있습니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 \
  --knowledges-root /Users/houston/Documents/Personals/knowledges
```

`--knowledges-root` 값은 `.git/`과 `raw/`를 포함하는 knowledges git clone 루트여야 합니다. 상대경로나 Obsidian vault alias는 허용하지 않습니다. 같은 값은 `SPAI_KNOWLEDGES_ROOT` 환경 변수로도 전달할 수 있고, 대화형으로 입력하려면 `--configure-knowledges-root`를 사용합니다.

project scope 설치 시 `gh`를 사용할 수 있으면 GitHub Repository 설정도 동기화합니다.

```text
Repository context:
  visibility and viewer permission: checked with gh repo view

General:
  Automatically delete head branches: enabled

Actions:
  Workflow permissions: read and write

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

private repository에서 classic branch protection 적용이 실패하면 installer는 repo visibility, 현재 계정 권한, GitHub API 오류를 warning으로 출력합니다. private repository의 protected branches는 GitHub plan 지원과 repository rules 수정 권한이 모두 필요합니다.

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
    knowledges-quick-ingest/
      SKILL.md
  rules/
    knowledges-raw-contract.md
  guardrails/
    knowledges-ingest.md
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
  knowledges-quick-ingest/
    SKILL.md
~/.agents/rules/
  knowledges-raw-contract.md
~/.agents/guardrails/
  knowledges-ingest.md
```

Codex는 repo/user skill 위치에 절차형 `SKILL.md`를 설치하고, knowledges raw contract와 ingest guardrail을 함께 설치합니다. `AGENTS.md`에 이미 SPAI marker가 있으면 해당 managed block만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 뒤에 추가합니다. 기존 파일 전체를 SP AI 템플릿으로 교체하려면 `--force`를 사용합니다.

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
    knowledges-quick-ingest/
      SKILL.md
  rules/
    knowledges-raw-contract.md
  guardrails/
    knowledges-ingest.md
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
  knowledges-quick-ingest/
    SKILL.md
~/.claude/rules/
  knowledges-raw-contract.md
~/.claude/guardrails/
  knowledges-ingest.md
```

Claude Code는 project/user skill을 `.claude/skills/<skill>/SKILL.md` 구조로 설치하고, knowledges rule/guardrail을 함께 설치합니다. `CLAUDE.md`에 이미 SPAI marker가 있으면 해당 managed block만 교체하고, marker가 없으면 기존 내용을 보존한 채 managed block을 뒤에 추가합니다. 기존 파일 전체를 SP AI 템플릿으로 교체하려면 `--force`를 사용합니다. 실제 Repository 설정 파일은 공통 project 파일로 `.github/`에 설치됩니다.

### Cursor

project scope:

```text
.cursor/
  rules/
    github-sync.mdc
    github-release.mdc
    develop-task-flow.mdc
    knowledges-quick-ingest.mdc
    knowledges-raw-contract.mdc
    knowledges-ingest-guardrails.mdc
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

Codex와 OpenCode는 project scope에서 모두 `AGENTS.md`를 사용합니다. SPAI는 동일한 managed block marker를 사용해 중복 삽입을 방지하고, marker가 없는 기존 파일은 보존한 채 managed block만 추가합니다. 기존 파일 전체를 SP AI 템플릿으로 교체하려면 `--force`를 사용합니다.

## 제공되는 스킬

현재 제공되는 절차형 스킬/룰/가드레일은 다음과 같습니다.

- `github-sync`: Release Drafter 파일, 표준 라벨, `main`/`develop` 브랜치, 브랜치 보호를 동기화합니다. 릴리스 생성에는 사용하지 않습니다.
- `github-release`: `origin/develop`에서 `release/vX.Y.Z`를 만들고 `main` 릴리스 PR을 통해 Release Drafter 게시를 진행합니다.
- `develop-task-flow`: 일반 개발 작업을 `origin/develop`에서 feature/fix/chore 브랜치로 시작하고 테스트, PR, develop 머지까지 진행합니다.
- `knowledges-quick-ingest`: 현재 프로젝트의 durable knowledge를 `.env`로 지정한 LLM + Obsidian Wiki + Graphify 기반 knowledges git repository의 `raw/` 하위에 provenance와 함께 추가합니다.
- `knowledges-raw-contract`: knowledges raw Markdown의 경로, frontmatter, body 구조 계약입니다.
- `knowledges-ingest`: secrets/privacy, batch size, Graphify 비용, `/sync`/`/resync` 범위를 제한하는 ingest guardrail입니다.

SPAI는 각 Agent 환경의 권장 instruction surface에 맞춰 위 절차를 설치합니다.

## Knowledges raw ingest 설정

현재 프로젝트에서 외부 knowledges repository로 raw 정보를 보낼 때는 `.env`에 cloned knowledges git repository의 절대경로를 설정합니다. 이 값은 Obsidian vault alias나 상대경로가 아니라 `.git/`과 `raw/`를 포함하는 repository root여야 합니다.

```dotenv
KNOWLEDGES_ROOT=/Users/houston/Documents/Personals/knowledges
```

`install.sh`는 다음 입력으로 `.env`의 `KNOWLEDGES_ROOT`를 생성하거나 갱신할 수 있습니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 \
  --knowledges-root /Users/houston/Documents/Personals/knowledges
```

Agent는 `.env`를 shell code로 실행하지 않고 `KNOWLEDGES_ROOT` 또는 `KNOWLEDGES_PROJECT_PATH` 값만 읽습니다. 작업 시 대상 repository의 `raw/` 하위 디렉토리를 먼저 살펴본 뒤, 외부 프로젝트 ingest는 기본적으로 다음 위치에 Markdown raw 파일을 생성하거나 갱신합니다.

```text
$KNOWLEDGES_ROOT/raw/inbox/<source_project>/<slug>.md
```

생성되는 raw 파일은 `date`, `tags`, `status`, `source_project`, `source_path`, `source_commit`, `source_updated_at`, `source_id`, `content_hash` frontmatter를 포함해야 합니다. Wiki 직접 수정과 전체 Graphify rebuild는 기본 동작이 아니며, 필요한 경우 knowledges repository의 `/sync`가 `graphify . --update`를 한 번 실행하도록 합니다. `.env`에는 로컬 절대경로가 들어가므로 커밋하지 않는 것을 권장합니다.

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
- 릴리즈 노트 `Changes` 출력 순서:
  - `Enhancement`
  - `Fixes`
  - `Chore`
  - `Summary`
- 릴리스 PR은 `patch`, `minor`, `major` 버전 업그레이드로 처리
- `patch`, `minor`, `major` 라벨은 버전 계산에만 사용하고 `Version Updates` 카테고리로 출력하지 않음
- `Contributors`는 GitHub가 별도로 노출하므로 릴리즈 본문에는 명시적으로 출력하지 않음
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

`dist/`는 `skills/github-sync`, `skills/github-release`, `skills/develop-task-flow`, `skills/knowledges-quick-ingest`, 그리고 `skills/github-release-setup/files/`에서 재생성됩니다. `rules/`와 `guardrails/`의 knowledges 파일도 함께 dist로 복사됩니다.

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
- `--dry-run`을 사용하면 실제 파일 시스템을 수정하지 않고 예정 작업을 출력하며, 파일과 managed block은 현재 내용과 비교해 missing/changed/PASS 상태를 구분합니다.
- project scope 설치 시 `.github/PULL_REQUEST_TEMPLATE.md`, `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`도 설치됩니다.
- project scope 설치는 `--github-account <account>` 또는 `SPAI_GITHUB_ACCOUNT=<account>` 입력이 필요합니다.
- knowledges raw ingest 설정은 `--knowledges-root <absolute-path>` 또는 `SPAI_KNOWLEDGES_ROOT=<absolute-path>`로 `.env`에 `KNOWLEDGES_ROOT`를 기록할 때만 적용됩니다.
- project scope 설치 시 `gh`, git repository, GitHub repository 확인이 가능하면 지정한 `gh` 계정으로 로그인/선택을 검증하고, 표준 6개 라벨만 남도록 라벨을 정리하고, `develop` 브랜치 생성, branch protection, Automatically delete head branches 설정을 동기화하며 가능한 범위에서 검증합니다.
- `.git` repository가 없으면 GitHub Repository 설정 동기화를 건너뛰고 통과 로그를 출력합니다.
- 원격 `develop` 브랜치가 없으면 `main`의 현재 commit에서 `develop`을 만든 뒤 branch protection을 적용합니다.
- 표준 6개 외의 기존 라벨은 삭제됩니다.
- `content` 라벨은 표준 라벨이 아니며, 신규 기능 또는 개선 사항은 `enhancement`로 처리합니다.
- Release Drafter 실행 결과는 대상 Repository의 GitHub Actions 권한과 branch protection 설정에 영향을 받습니다.

## License

MIT License
