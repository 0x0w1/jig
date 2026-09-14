# 설치 가이드

[English](../en/installation.md)

jig는 지원하는 CLI마다 **설치 경로가 다릅니다.** 한 번에 전부 설치하는 방법은 없고 쓰는 CLI만 골라 설치합니다.

| CLI | 설치 방식 | 배포 단위 | 소유자 |
|---|---|---|---|
| Claude Code | 플러그인 마켓플레이스 | `jig` 플러그인 | Claude Code 호스트 |
| Codex | 플러그인 마켓플레이스 | `jig` 플러그인 | Codex 호스트 |
| Antigravity CLI | `install.sh` | `.agents/skills/jig-*` 파일 | jig installer |

명령만 필요하면 [README의 빠른 시작](../../README.ko.md#빠른-시작)을 보세요. 이 문서는 각 방식이 **무엇을 어디에 설치하고 이후 어떻게 관리되는지**를 설명합니다.

설치는 target별로 한 번씩 수행하지만 업데이트는 통합합니다. `jig-update`를 한 번 실행하면 현재 프로젝트의 `project`/`local` 범위와 사용자 전역 범위에서 Claude Code, Codex, Antigravity 설치를 모두 찾고 발견된 인스턴스를 함께 갱신합니다. 어느 에이전트에서 실행했는지는 업데이트 대상을 제한하지 않으며, 기존에 없던 target이나 범위를 새로 설치하지 않습니다.

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

`CLAUDE.md`는 **건드리지 않습니다.** 플러그인 스킬은 호스트가 frontmatter의 `description`으로 직접 노출하므로 규칙 파일에 스킬 목록을 또 적을 이유가 없습니다.

### 활용

스킬은 호스트가 네임스페이스를 붙여 호출합니다.

```text
/jig:github-sync
/jig:develop-task-flow
/jig:github-release
/jig:jig-setup
/jig:jig-update
/jig:jig-doctor
/jig:readme
/jig:version-rubric
/jig:rubric-scan
```

이름이 같은 커스텀 스킬(`/github-release`)이 있어도 **양쪽 모두 그대로 남습니다.** 네임스페이스가 다르기 때문입니다.

### 버전 관리

버전은 호스트가 관리합니다. 저장소에 버전 스탬프를 남기지 않습니다.

```text
/plugin marketplace update jig          # 최신으로 갱신
/reload-plugins                          # 현재 세션에 반영
```

특정 릴리즈에 고정하려면 마켓플레이스를 태그 ref로 다시 등록합니다.

```text
/plugin marketplace add https://github.com/your-account/jig.git#v0.2.0
```

### 기존 standalone 스킬

마켓플레이스 플러그인이 계속 공식 설치 경로입니다. 다만 `jig-update`는 `./.claude/skills` 또는 `~/.claude/skills`에 이미 존재하는 이전 설치나 수동 복사 방식의 standalone jig 스킬 세트도 인식하며, 새로운 standalone 설치를 만들지는 않습니다.

첫 compatibility update가 성공하면 루트의 `.jig-installation` 원장에 릴리즈 버전, target, scope, 정확한 스킬-디렉터리 선택을 기록하고 소유한 각 스킬 디렉터리에 `.jig-provenance` marker를 만듭니다. 최초 원장이 없는 기존 설치는 frontmatter 이름과 canonical payload 제목이 모두 맞는 디렉터리만 인정하며, 이름만 같은 디렉터리는 변경하지 않습니다. 이후 업데이트에서는 원장과 marker가 서로 일치해야 합니다.

각 standalone 루트는 하나의 transaction으로 업데이트됩니다. `jig-update`는 선택한 payload 파일을 모두 내려받은 뒤 설치본을 변경하고, 바뀌는 파일을 `.bak`으로 보존하며, 파일 하나라도 적용하지 못하면 기존 파일·백업·marker·원장을 이전 상태로 복구합니다.

파일을 내려받기 전에 updater는 선택한 모든 `dist/files.tsv` 항목이 엄격한 상대 파일 경로인지 검증합니다. 절대 경로, 빈 구성요소, traversal, 예약 marker·backup 이름, 지원하지 않는 문자, 기존 symlink 구성요소는 거부합니다. catalog를 거부한 standalone 루트에서는 backup, provenance marker, 원장을 포함해 아무 파일도 변경하지 않습니다.

이 경로에는 개인 스킬도 함께 있을 수 있으므로 디렉터리 존재만으로 jig 설치라고 판단하지 않습니다. updater는 파일을 바꾸기 전에 `jig-update/SKILL.md`에서 jig의 이름·제목·`0x0w1/jig` 저장소 identity를 모두 확인합니다. 확인 후에는 이미 존재하는 jig 스킬 디렉터리만 갱신하고 unprefixed 또는 `jig-` prefixed 이름을 보존하며, 선택된 디렉터리 내부에만 새 supporting file을 추가하고 바뀌는 파일은 모두 `.bak`으로 백업합니다. 판별되지 않은 경로는 건드리지 않습니다.

`jig-doctor`는 `jig-update`와 같은 설치 inventory 계약을 사용합니다. 두 standalone 루트를 파일 변경 없이 검사해 verified, legacy-unledgered, invalid-ledger, partial, provenance-conflict, non-owned 상태를 구분하고, 감지한 모든 Claude Code plugin, Codex, Antigravity scope와 함께 보고합니다.

### 제거

플러그인을 제거하기 전에 `/jig:github-sync`에 현재 저장소의 local pre-push guard 제거를 요청합니다. 플러그인 호스트는 플러그인 파일을 제거하지만 clone-local `.git/hooks` 파일까지 자동 정리할 수는 없습니다.

```text
/plugin uninstall jig@jig    # 완전 제거
/plugin disable jig@jig      # 비활성화만
```

---

## Codex

### 설치되는 것

Codex에는 플러그인 시스템이 있어, jig는 Claude Code와 같은 플러그인을 같은 마켓플레이스 저장소에서 설치합니다. installer는 관여하지 않습니다.

```bash
codex plugin marketplace add 0x0w1/jig
codex plugin add jig@jig
```

플러그인은 `${CODEX_HOME:-~/.codex}/plugins/` 아래에 캐시되고 설치 사실은 `${CODEX_HOME:-~/.codex}/config.toml`에 기록됩니다.

```toml
[marketplaces.jig]
source_type = "git"
source = "https://github.com/0x0w1/jig.git"

[plugins."jig@jig"]
enabled = true
```

저장소에는 아무것도 쓰지 않습니다. 설치는 user-global이므로 그 머신의 모든 저장소에서 스킬이 보입니다.

### 활용

번들된 스킬은 플러그인 이름으로 네임스페이스되어 `jig:github-sync`, `jig:jig-doctor`처럼 로드됩니다. Claude Code와 같은 이름이고 앞의 슬래시만 없습니다. 설치 목록은 `codex plugin list`로 확인합니다.

### push 가드

Codex는 플러그인 자체의 hook을 실행하지 않으므로 `PreToolUse` push 가드는 플러그인에 실려 가지 않습니다. 대신 `jig:github-sync`가 `.codex/hooks.json`에 저장소 hook 항목을 설치하고, 그 항목이 clone-local guard 복사본을 가리킵니다. Codex는 비관리 hook을 `/hooks`에서 한 번 검토·신뢰한 뒤에만 실행합니다.

### 버전 관리

플러그인은 host가 관리하며 jig 버전 스탬프를 갖지 않습니다. 갱신은 다음과 같습니다.

```bash
codex plugin marketplace upgrade jig
codex plugin add jig@jig
```

`jig-update`가 이 두 명령을 대신 실행하고, CLI가 없으면 Codex를 pending으로 보고합니다.

### 제거

플러그인을 제거하기 전에 `jig:github-sync`에 현재 저장소의 local guard 제거를 요청합니다 — `.codex/hooks.json`의 네이티브 hook 항목, 그다음 pre-push hook. cleanup은 jig 자신의 항목과 jig marker가 있는 hook만 제거하고 사용자 항목은 모두 보존하며 jig가 백업한 사용자 hook이 있으면 복원합니다.

```bash
codex plugin remove jig@jig
codex plugin marketplace remove jig
```

### 파일 설치본에서 옮겨오기

v0.22.0 이전에는 installer가 `jig-` prefix 스킬 파일을 `.agents/skills`에 복사하고 `AGENTS.md`에 managed block을 썼습니다. 그 설치본은 계속 로드되지만 installer가 더 이상 Codex를 대상으로 하지 않으므로 갱신되지 않습니다. 옮기려면 위 두 명령으로 플러그인을 설치한 뒤 `AGENTS.md`에서 `<!-- jig:start ... -->`와 `<!-- jig:end ... -->` 사이를 지웁니다. **`.agents/skills/jig-*`는 같은 저장소에 Antigravity가 설치돼 있지 않을 때만 지웁니다** — 두 CLI가 같은 디렉터리를 읽습니다.

---

## Antigravity CLI

### 설치되는 것

Antigravity에는 플러그인 시스템이 없어 installer가 파일을 복사합니다.

project scope:

```text
./GEMINI.md                       # jig managed block 추가/교체
.agents/skills/jig-*/
```

global scope:

```text
~/.gemini/GEMINI.md
~/.gemini/config/skills/jig-*/
```

### 활용

Antigravity CLI는 워크스페이스 루트의 `GEMINI.md`를 규칙 파일로 읽고 `.agents/skills/*`에서 네이티브 스킬을 인식합니다.

**legacy Codex 파일 설치본과 project scope 경로(`.agents/skills`)를 공유합니다.** 스킬 파일 내용이 같아 안전하고 규칙 파일만 `GEMINI.md`와 `AGENTS.md`로 각각 생깁니다. Codex를 플러그인으로 옮길 때 Antigravity가 아직 설치돼 있으면 `.agents/skills/jig-*`를 지우면 안 되는 이유이기도 합니다.

### 버전 관리와 제거

설치 버전과 스킬 구성은 `GEMINI.md`의 managed block 안에 스탬프되고 `jig-update`가 이 스탬프를 읽어 같은 구성으로 최신 릴리즈에 재설치합니다. 제거할 때는 `jig-github-sync`로 guard를 먼저 정리하고 `.agents/skills/jig-*`를 지운 뒤 `GEMINI.md`에서 jig marker 사이 구간만 지웁니다.

---

## installer 공통 동작

Antigravity 설치에만 해당합니다. Claude Code와 Codex는 각자의 마켓플레이스에서 `jig` 플러그인을 설치합니다.

### installer 옵션

| 옵션 | 설명 |
|---|---|
| `--target antigravity` | 설치할 CLI 지정(필수). 값은 `antigravity` 하나이며 `codex`와 `claude-code`는 플러그인을 씁니다 |
| `--scope project\|global` | 설치 범위, 기본값 `project` |
| `--github-profile <profile>` | 설치 중 GitHub 연동까지 할 때 프로필 지정(선택). `--github-account`도 호환 |
| `--github-host <host>` | GitHub Enterprise 호스트 지정 |
| `--version vX.Y.Z` | 특정 jig 릴리즈로 설치·롤백 |
| `--skills a,b,c` | manifest에서 선택한 스킬만 설치 |
| `--configure-git-user` | 로컬 `user.name`·`user.email` 설정 |
| `--dry-run` | 파일을 바꾸지 않고 예정 작업만 출력 |
| `--force` | jig marker가 없는 기존 managed 파일을 전체 교체 |

installer는 Antigravity 전용입니다. Claude Code와 Codex는 각자의 플러그인 호스트가 설치·업데이트·삭제를 전담하므로 `install.sh`를 쓰지 않습니다.

기본 설치 중에는 로컬 git user 변경 prompt를 띄우지 않습니다. `gh` 로그인이 필요하거나 `--configure-git-user`를 쓰면 터미널 입력이 필요할 수 있습니다.

### 예약 이름

jig는 `jig` 플러그인 이름과 `jig-`로 시작하는 스킬 이름만 점유합니다. 직접 만든 스킬에 `jig-` prefix만 쓰지 않으면 충돌하지 않습니다. Claude Code는 호스트가 네임스페이스를 붙이므로 이름이 같아도 양쪽 모두 남습니다.

### 멱등성

installer는 쓰기 전에 현재 상태를 먼저 확인하고 이미 원하는 상태면 `PASS` 로그만 남기고 건너뜁니다. 변경이 필요한 파일은 `.bak` 백업을 만든 뒤 교체합니다.

`--dry-run`으로 실제 변경 없이 예정 작업만 확인할 수 있습니다.

### managed block

`GEMINI.md`(그리고 legacy Codex 파일 설치본의 `AGENTS.md`)는 marker 사이 구간만 jig가 소유합니다.

- marker가 있으면 그 구간만 교체합니다.
- marker가 없으면 기존 내용을 **보존한 채** 파일 끝에 블록을 덧붙입니다.
- 파일 전체를 jig 템플릿으로 교체하려면 `--force`를 씁니다.

### 스킬 선택 설치

`--skills a,b`로 일부만 설치할 수 있습니다. 생략하면 `manifest.tsv`의 기본 스킬 전부가 설치되고 선택 설치 시 managed block 목록에서도 제외된 스킬이 빠집니다.

### 버전 해석

기본값은 최신 GitHub 릴리즈 태그입니다. 조회에 실패하면 `main` 브랜치로 폴백합니다.

- `--version vX.Y.Z` 또는 `JIG_VERSION`: 특정 릴리즈에 고정하거나 롤백
- `REPO_RAW_URL`: 버전 해석을 건너뛰고 해당 URL을 그대로 사용

### GitHub 설정 동기화

project scope에서 GitHub 프로필이 이미 설정되어 있고 `gh`를 쓸 수 있으면 installer가 추가로 수행합니다.

1. `JIG_GITHUB_PROFILE`, 로컬 `jig.githubProfile`, 또는 `--github-profile`로 프로필을 정하고 필요하면 `gh auth login`을 실행합니다. 선택한 프로필의 credential을 명령별로 사용하며 전역 active account는 바꾸지 않습니다.
2. 원격에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 만듭니다.

프로필이 없으면 스킬 파일 설치는 그대로 완료하고 이 단계만 `jig-setup` 이후로 미룹니다. `.git` repository가 없거나 GitHub 저장소에 연결돼 있지 않아도 이 단계를 건너뛰고 통과 로그를 남깁니다.

**branch protection은 installer가 설정하지 않습니다.** 종료 시 `GUIDE`로 안내만 하고 실제 적용은 `github-sync` 스킬이 담당합니다. 자세한 조건은 [GitHub Repository Settings](github-repository-settings.md)를 참고하세요.

### 저장소별 GitHub 프로필

지속 설정은 저장소의 `.git/config`에 로그인 이름과 호스트만 저장합니다. OAuth token은 `gh` credential store에 그대로 둡니다.

```bash
git config --local jig.githubProfile your-account
git config --local jig.githubHost github.com
```

일회성 또는 세션별 override는 에이전트를 시작하는 환경에 지정합니다.

```bash
JIG_GITHUB_PROFILE=your-account JIG_GITHUB_HOST=github.com <agent-command>
```

환경변수가 로컬 config보다 우선합니다. 어느 방식이든 jig 스킬은 `gh auth switch`를 실행하지 않습니다.

### 로컬 git 작성자

기본 설치에서는 묻지 않습니다. 필요할 때만 옵션으로 켭니다.

```bash
sh install.sh --target antigravity --scope project --configure-git-user
```

비대화식으로 값을 직접 넘길 수도 있습니다.

```bash
sh install.sh --target antigravity --scope project \
  --git-user-name "Your Name" --git-user-email "your@email.com"
```

---

## 설치 후 첫 단계

어느 CLI로 설치했든 GitHub 프로필은 설치가 끝난 뒤 설정할 수 있습니다. `jig-setup` 스킬을 실행해 설치 상태와 프로필을 검증하고 저장소를 jig 브랜치 모델에 수렴시킵니다.

- Claude Code: `/jig:jig-setup`
- Codex: `jig:jig-setup`
- Antigravity: `jig-setup`

이 스킬은 토큰을 저장하지 않고 `JIG_GITHUB_PROFILE` 또는 로컬 `git config`의 프로필 이름만 사용합니다. 이어서 `github-sync`가 `develop` 브랜치를 보장하고 branch protection을 물어본 뒤 정하며, `jig-doctor`가 상태를 점검합니다.
