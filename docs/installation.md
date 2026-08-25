# 설치 가이드

SPAI는 지원하는 CLI마다 **설치 경로가 다릅니다.** 한 번에 전부 설치하는 방법은 없고, 쓰는 CLI만 골라 설치합니다.

| CLI | 설치 방식 | 배포 단위 | 소유자 |
|---|---|---|---|
| Claude Code | 플러그인 마켓플레이스 | `spai` 플러그인 | Claude Code 호스트 |
| Codex | `install.sh` | `.agents/skills/spai-*` 파일 | SPAI installer |
| Antigravity CLI | `install.sh` | `.agents/skills/spai-*` 파일 | SPAI installer |

명령만 필요하면 [README의 설치 방법](../README.md#설치-방법)을 보세요. 이 문서는 각 방식이 **무엇을 어디에 설치하고, 이후 어떻게 관리되는지**를 설명합니다.

---

## Claude Code

### 설치되는 것

플러그인은 스킬 파일을 저장소에 복사하지 않습니다. 마켓플레이스를 등록하고 플러그인을 설치하면 Claude Code가 자체 플러그인 디렉토리에 내려받아 로드합니다.

project scope로 설치하면 저장소에 남는 파일은 설정 하나뿐입니다.

```text
.claude/
  settings.json    # extraKnownMarketplaces + enabledPlugins
```

이 파일을 커밋하면 협업자는 저장소를 열 때 같은 플러그인을 받습니다. user scope로 설치하면 `~/.claude/settings.json`에 기록되고 저장소에는 아무것도 남지 않습니다.

`CLAUDE.md`는 **건드리지 않습니다.** 플러그인 스킬은 호스트가 frontmatter의 `description`으로 직접 노출하므로, 규칙 파일에 스킬 목록을 또 적을 이유가 없습니다.

### 활용

스킬은 호스트가 네임스페이스를 붙여 호출합니다.

```text
/spai:github-sync
/spai:develop-task-flow
/spai:github-release
/spai:project-setup
/spai:spai-update
/spai:spai-doctor
/spai:readme
```

이름이 같은 커스텀 스킬(`/github-release`)이 있어도 **양쪽 모두 그대로 남습니다.** 네임스페이스가 다르기 때문입니다.

### 버전 관리

버전은 호스트가 관리합니다. 저장소에 버전 스탬프를 남기지 않습니다.

```text
/plugin marketplace update spai          # 최신으로 갱신
/reload-plugins                          # 현재 세션에 반영
```

특정 릴리즈에 고정하려면 마켓플레이스를 태그 ref로 다시 등록합니다.

```text
/plugin marketplace add https://github.com/your-account/spai.git#v0.2.0
```

### 제거

```text
/plugin uninstall spai@spai    # 완전 제거
/plugin disable spai@spai      # 비활성화만
```

---

## Codex

### 설치되는 것

Codex에는 플러그인 시스템이 없어 installer가 파일을 복사합니다.

project scope:

```text
./AGENTS.md                       # SPAI managed block 추가/교체
.agents/skills/
  spai-github-sync/SKILL.md
  spai-github-release/SKILL.md
  spai-develop-task-flow/SKILL.md
  spai-project-setup/SKILL.md
  spai-update/SKILL.md
  spai-doctor/SKILL.md
  spai-readme/SKILL.md
  spai-version-rubric/SKILL.md
  spai-version-rubric/rubrics/      # 프로젝트 유형별 기준 카탈로그
  spai-rubric-scan/SKILL.md
```

스킬은 파일 하나가 아니라 디렉토리입니다. `spai-version-rubric`처럼 참조 파일을 함께 배포하는 스킬은 `SKILL.md` 외의 파일도 같이 설치됩니다. installer는 릴리즈의 `dist/files.tsv`에 적힌 목록대로 내려받습니다.

global scope:

```text
~/.codex/AGENTS.md
~/.agents/skills/spai-*/
```

### 활용

`.agents/skills/*`의 `SKILL.md`를 Codex가 네이티브 스킬로 인식합니다. 디렉토리 이름과 frontmatter `name`에 모두 `spai-` prefix가 붙으므로 직접 만든 스킬과 이름이 겹치지 않습니다. `AGENTS.md`의 managed block은 설치된 스킬 목록만 담고, 절차 본문은 각 `SKILL.md`에서 로드됩니다.

### 버전 관리

설치 버전과 스킬 구성은 managed block 안에 스탬프됩니다.

```text
<!-- spai:version v0.2.0 skills=github-sync,github-release,develop-task-flow,project-setup,spai-update,spai-doctor -->
```

`spai-update` 스킬이 이 스탬프를 읽어 같은 구성으로 최신 릴리즈에 재설치하고, `spai-doctor`가 진단 기준으로 씁니다. 업데이트는 같은 명령을 다시 실행하면 됩니다 — installer는 멱등이라 변경된 파일만 갱신합니다.

### 제거

installer는 파일을 지우지 않습니다. 직접 지웁니다.

```bash
rm -rf .agents/skills/spai-github-sync .agents/skills/spai-github-release \
  .agents/skills/spai-develop-task-flow .agents/skills/spai-update .agents/skills/spai-doctor \
  .agents/skills/spai-project-setup .agents/skills/spai-readme \
  .agents/skills/spai-version-rubric .agents/skills/spai-rubric-scan
```

`AGENTS.md`에서는 `<!-- spai:start ... -->`와 `<!-- spai:end ... -->` 사이 구간만 지우면 됩니다. 블록 바깥 내용은 SPAI가 건드린 적이 없습니다.

---

## Antigravity CLI

### 설치되는 것

Codex와 같은 파일 복사 방식이고, 규칙 파일 이름과 global scope 경로만 다릅니다.

project scope:

```text
./GEMINI.md                       # SPAI managed block 추가/교체
.agents/skills/spai-*/
```

global scope:

```text
~/.gemini/GEMINI.md
~/.gemini/config/skills/spai-*/
```

### 활용

Antigravity CLI는 워크스페이스 루트의 `GEMINI.md`를 규칙 파일로 읽고 `.agents/skills/*`에서 네이티브 스킬을 인식합니다.

**Codex와 project scope 경로(`.agents/skills`)를 공유합니다.** 두 CLI를 같은 저장소에 설치해도 스킬 파일은 같은 내용이라 안전하고, 규칙 파일만 `AGENTS.md`와 `GEMINI.md`로 각각 생깁니다.

### 버전 관리와 제거

Codex와 동일합니다. 스탬프는 `GEMINI.md`의 managed block에 들어갑니다.

---

## installer 공통 동작

Codex와 Antigravity 설치에만 해당합니다.

### 멱등성

installer는 쓰기 전에 현재 상태를 먼저 확인하고, 이미 원하는 상태면 `PASS` 로그만 남기고 건너뜁니다. 변경이 필요한 파일은 `.bak` 백업을 만든 뒤 교체합니다.

`--dry-run`으로 실제 변경 없이 예정 작업만 확인할 수 있습니다.

### managed block

`AGENTS.md`와 `GEMINI.md`는 marker 사이 구간만 SPAI가 소유합니다.

- marker가 있으면 그 구간만 교체합니다.
- marker가 없으면 기존 내용을 **보존한 채** 파일 끝에 블록을 덧붙입니다.
- 파일 전체를 SPAI 템플릿으로 교체하려면 `--force`를 씁니다.

### 스킬 선택 설치

`--skills a,b`로 일부만 설치할 수 있습니다. 생략하면 `manifest.tsv`의 기본 스킬 전부가 설치되고, 선택 설치 시 managed block 목록에서도 제외된 스킬이 빠집니다.

### 버전 해석

기본값은 최신 GitHub 릴리즈 태그입니다. 조회에 실패하면 `main` 브랜치로 폴백합니다.

- `--version vX.Y.Z` 또는 `SPAI_VERSION`: 특정 릴리즈에 고정하거나 롤백
- `REPO_RAW_URL`: 버전 해석을 건너뛰고 해당 URL을 그대로 사용

### GitHub 설정 동기화

project scope에서 GitHub 프로필이 이미 설정되어 있고 `gh`를 쓸 수 있으면 installer가 추가로 수행합니다.

1. `SPAI_GITHUB_PROFILE`, 로컬 `spai.githubProfile`, 또는 `--github-profile`로 프로필을 정하고, 필요하면 `gh auth login`을 실행합니다. 선택한 프로필의 credential을 명령별로 사용하며 전역 active account는 바꾸지 않습니다.
2. 원격에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 만듭니다.

프로필이 없으면 스킬 파일 설치는 그대로 완료하고 이 단계만 `project-setup` 이후로 미룹니다. `.git` repository가 없거나 GitHub 저장소에 연결돼 있지 않아도 이 단계를 건너뛰고 통과 로그를 남깁니다.

**branch protection은 installer가 설정하지 않습니다.** 종료 시 `GUIDE`로 안내만 하고, 실제 적용은 `github-sync` 스킬이 담당합니다. 자세한 조건은 [GitHub Repository Settings](github-repository-settings.md)를 참고하세요.

### 저장소별 GitHub 프로필

지속 설정은 저장소의 `.git/config`에 로그인 이름과 호스트만 저장합니다. OAuth token은 `gh` credential store에 그대로 둡니다.

```bash
git config --local spai.githubProfile your-account
git config --local spai.githubHost github.com
```

일회성 또는 세션별 override는 에이전트를 시작하는 환경에 지정합니다.

```bash
SPAI_GITHUB_PROFILE=your-account SPAI_GITHUB_HOST=github.com <agent-command>
```

환경변수가 로컬 config보다 우선합니다. 어느 방식이든 SPAI 스킬은 `gh auth switch`를 실행하지 않습니다.

### 로컬 git 작성자

기본 설치에서는 묻지 않습니다. 필요할 때만 옵션으로 켭니다.

```bash
sh install.sh --target codex --scope project --configure-git-user
```

비대화식으로 값을 직접 넘길 수도 있습니다.

```bash
sh install.sh --target codex --scope project \
  --git-user-name "Your Name" --git-user-email "your@email.com"
```

---

## 설치 후 첫 단계

어느 CLI로 설치했든 GitHub 프로필은 설치가 끝난 뒤 설정할 수 있습니다. `project-setup` 스킬을 실행해 설치 상태와 프로필을 검증하고 저장소를 SPAI 브랜치 모델에 수렴시킵니다.

- Claude Code: `/spai:project-setup`
- Codex / Antigravity: `spai-project-setup`

이 스킬은 토큰을 저장하지 않고 `SPAI_GITHUB_PROFILE` 또는 로컬 `git config`의 프로필 이름만 사용합니다. 이어서 `github-sync`가 `develop` 브랜치와 branch protection을 수렴시키고, `spai-doctor`가 상태를 점검합니다.
