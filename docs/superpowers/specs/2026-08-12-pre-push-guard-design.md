# SPAI 로컬 가드 (git pre-push hook) 설계

> 상태: 승인된 설계 (2026-08-12)
> 다음 릴리즈 영향: 새 capability → `minor` (v0.5.0 예상)

## 목적

GitHub branch protection과 별개로, SPAI가 설치하는 **로컬 방어선**을 제공한다. 서버측 protection이 최종 방어로 남고, 로컬 방어선은 위반을 실행 시점에 조기 차단한다. 구조는 2층이다:

1. **git `pre-push` hook (공통 기반)** — Claude Code/Codex/Antigravity 어느 CLI가 실행하든, 사람이 터미널에서 직접 push하든 동일하게 작동하는 유일한 층.
2. **Claude Code 플러그인 hook (네이티브 층)** — `spai` 플러그인에 포함되는 PreToolUse hook. 명령 문자열을 실행 전에 검사하므로 git hook의 유일한 구멍인 `--no-verify` 우회까지 Claude Code에서는 차단한다.

Codex/Antigravity의 네이티브 hook은 채택하지 않고 roadmap 후보로 보류한다 (아래 범위 밖 참조).

## 결정 사항

| 항목 | 결정 |
|---|---|
| 메커니즘 | git `pre-push` hook (POSIX sh), `.git/hooks/pre-push` |
| 차단 범위 | force push, 보호 브랜치 원격 삭제, `main` 직접 push |
| 배포 | 스크립트 전문을 `github-sync` 스킬 본문에 heredoc으로 포함, 스킬이 생성·수렴 |
| 진단 | `spai-doctor`가 존재·버전 마커·규칙 문자열 검사 (read-only 유지) |
| 업데이트 승계 | `spai-update` → `github-sync` 재수렴 경로로 자동 |
| 우회 정책 | `--no-verify`는 git hook으로 못 막음 → Safety Rules에 금지 명시 + Claude Code에서는 플러그인 hook이 명령 문자열 검사로 차단 |
| Claude Code 네이티브 hook | **채택** — 플러그인에 `hooks/hooks.json` PreToolUse 포함, 호스트가 설치·수명주기 전담 |
| Codex/Antigravity 네이티브 hook | 보류 — Codex는 experimental·기본 비활성(feature flag 필요), Antigravity는 사용자 소유 설정 파일 편집 필요. git hook이 커버. 트리거: hook GA/안정화 + git hook으로 못 막는 실사례 |

## hook 규칙

`pre-push`는 push되는 ref마다 stdin으로 `<local ref> <local sha> <remote ref> <remote sha>`를 받는다. 보호 브랜치는 `refs/heads/main`, `refs/heads/develop`.

| 규칙 | 판정 | 거부 조건 |
|---|---|---|
| 삭제 차단 | local sha == zero-sha | remote ref가 보호 브랜치 |
| force 차단 | `git merge-base --is-ancestor <remote sha> <local sha>` 실패 (non-ff) | remote ref가 보호 브랜치이고 remote sha가 zero-sha 아님 |
| main 직접 push 제한 | local ref != `refs/heads/develop` | remote ref == `refs/heads/main`. 릴리즈 `git push origin develop:main`만 통과 |

- 거부 메시지는 위반한 규칙과 올바른 절차(예: "release는 `git push origin develop:main`으로")를 함께 출력한다 — fail loud, names its own fix.
- 스크립트 상단에 버전 마커 주석 한 줄: `# spai:pre-push v1`. 규칙이 바뀌면 v2로 올린다.
- 원격 저장소가 어디든(GitHub 아니어도) 동작한다. 서버측 protection과 독립.

## 설치·수렴 모델 (`github-sync`)

1. `.git/hooks/pre-push`가 없으면 스크립트를 생성하고 실행 권한을 준다.
2. 이미 있고 `# spai:pre-push` 마커가 있으면: 버전이 낮을 때만 갱신 (멱등).
3. 이미 있는데 마커가 없으면(사용자 훅): **중단하고 보고**, 사용자 확인 후에만 `.bak` 백업 뒤 교체. 사용자 파일을 무단으로 덮어쓰지 않는다.
4. `core.hooksPath` 방식은 쓰지 않는다 — 사용자 훅 디렉토리 전체를 무력화하기 때문.
5. `.git` 저장소가 아니면 건너뛰고 통과 로그를 남긴다 (installer의 관례와 동일).

## Claude Code 플러그인 hook

- 플러그인 payload에 두 파일 추가: `hooks/hooks.json`(PreToolUse, matcher `Bash`, `${CLAUDE_PLUGIN_ROOT}` 경로로 스크립트 실행)과 `hooks/guard-push.sh`(POSIX sh).
- 스크립트는 stdin JSON에서 실행될 명령 문자열을 읽어 `git push` 위반 패턴을 검사한다:
  - 보호 브랜치 대상 `--force`/`-f`/`--force-with-lease`
  - 보호 브랜치 삭제 refspec (`:main`, `:develop`, `--delete`)
  - `develop:main` 이외의 `main` push
  - 보호 브랜치 push에 `--no-verify` 동반
- 위반이면 차단 종료 코드와 함께 stderr로 규칙·올바른 절차를 출력한다. **판정이 불확실하면 통과** (fail-open) — 오탐으로 절차를 막지 않고, 최종 방어는 git hook과 서버측 protection이 담당한다.
- 원본은 저장소 `hooks/` 디렉토리에 두고 `build-dist.sh`가 플러그인 payload로 복사한다. 설치·업데이트·제거는 플러그인 호스트가 전담하므로 installer·`github-sync` 변경 없음.
- Codex/Antigravity 설치본에는 이 층이 없다 — git hook이 유일한 로컬 방어선.

## 진단 (`spai-doctor`)

- `.git/hooks/pre-push` 존재 여부
- `# spai:pre-push v<N>` 마커와 버전 (스킬이 아는 최신 버전과 비교, 구버전이면 `github-sync` 재실행 안내)
- 세 규칙의 핵심 문자열 존재 (지역 수정 감지)
- 실행 권한
- 보고만 하고 고치지 않는다. 수정은 `github-sync` 재실행으로 안내.

## 변경 범위

- `skills/github-sync/SKILL.md`: hook 설치·수렴 절차 + 스크립트 전문(heredoc)
- `skills/spai-doctor/SKILL.md`: 진단 항목 추가
- `skills/develop-task-flow/SKILL.md`, `skills/github-release/SKILL.md`: Safety Rules에 "git hook 우회(`--no-verify`) 금지" 추가
- 신규 `hooks/hooks.json`, `hooks/guard-push.sh`: Claude Code 플러그인 hook 원본
- `scripts/build-dist.sh`: 플러그인 payload에 `hooks/` 복사, `scripts/validate-dist.sh`: hook 파일·핵심 문자열 검사 추가
- 사본 동기화: `.agents/skills/spai-*` 4종, `.claude/skills/*` 해당 스킬
- `dist/` 재생성, `docs/github-repository-settings.md`·`README.md`·`docs/roadmap.md` 갱신 (roadmap에 Codex/Antigravity 네이티브 hook 보류 후보 기록)
- installer 변경 없음 (git hook은 저장소 상태 → `github-sync` 소관, Claude hook은 플러그인 호스트 소관)

## 검증

- 이 저장소에 실제 설치 후, `git push --dry-run`으로 검증한다 (`--dry-run`도 `pre-push` hook을 실행하므로 원격 상태를 바꾸지 않고 판정만 확인할 수 있다):
  - 보호 브랜치 대상 force push (`--force --dry-run`) → 거부
  - `git push --dry-run origin :develop` (삭제) → 거부
  - develop 아닌 ref에서 main push (`--dry-run`) → 거부
  - 일반 feature push, `develop` push (`--dry-run`) → 통과
- Claude Code hook 스크립트: 위반/통과 명령 샘플을 stdin JSON으로 넣어 종료 코드를 직접 확인 (위반 4종 차단, 일반 push·비-git 명령 통과)
- `sh scripts/validate-dist.sh` 통과

## 범위 밖

- 로컬 브랜치 삭제(`git branch -D`) 차단 — 채택 안 함 (사용자 확인)
- Codex/Antigravity 네이티브 hook — 보류. 트리거: 해당 CLI hook의 GA/안정화 + git hook으로 못 막는 실사례 발생
- pre-commit 등 다른 git hook — 필요 신호 없음
