# GitHub Repository Settings

[English](../en/github-repository-settings.md)

이 문서는 `install.sh`(Codex, Antigravity CLI 대상)의 GitHub 동작을 설명합니다. Claude Code는 플러그인으로 설치되어 installer를 거치지 않으므로 저장소 프로필 설정과 수렴은 설치 후 `/jig:jig-setup`으로 처리합니다.

jig project scope 스킬 설치에는 GitHub 프로필이 필요하지 않습니다. 프로필 없이 설치하면 GitHub Repository 설정 동기화만 건너뜁니다. 설치된 `jig-setup`이 이후 `JIG_GITHUB_PROFILE` 또는 로컬 `jig.githubProfile`을 설정합니다. 프로필 credential은 명령별 환경으로 전달하며 전역 active account를 바꾸지 않습니다.

## Repository 운영 규칙

- 일반 변경은 현재 `origin/develop`에서 `feature/*`, `fix/*`, `chore/*` 브랜치를 생성해 작업하고 완료 후 로컬에서 `git merge --squash`로 `develop`에 병합해 push합니다. Pull Request는 사용하지 않습니다.
- `develop`의 squash 커밋 제목은 conventional prefix(`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`)를 사용합니다.
- 릴리즈는 사용자가 명시적으로 요청한 경우에만 진행합니다. `git push origin develop:main`(fast-forward만 허용)으로 `develop`을 `main`으로 승격한 뒤 CLI에서 `vX.Y.Z` 태그와 GitHub 릴리즈를 생성합니다. 릴리즈 PR, `release/*` 브랜치, release-drafter는 사용하지 않습니다.
- 릴리즈 요청 안에 아직 `develop`에 병합되지 않은 코드, 설정, 문서, 생성된 `dist`, 설치 스크립트 변경이 있으면 릴리즈를 중단하고 먼저 일반 작업 flow를 완료합니다.

## install.sh가 적용하는 항목

`install.sh --target <codex|antigravity> --scope project`는 Agent 스킬/룰 파일을 먼저 설치합니다. 프로필이 이미 제공된 경우에만 이어서 다음 GitHub 작업을 시도합니다.

- GitHub CLI 계정 선택:
  - `--github-profile` → `JIG_GITHUB_PROFILE` → 로컬 `jig.githubProfile` 순서로 프로필을 확정합니다.
  - `--github-account`와 `JIG_GITHUB_ACCOUNT`는 호환 alias로 유지합니다.
  - 입력 받은 계정이 `gh`에 없으면 `gh auth login`을 실행합니다.
  - `gh auth token --user <profile>`로 credential을 읽어 각 `gh` 명령에만 전달합니다. 토큰은 출력하거나 파일에 저장하지 않습니다.
  - GitHub Enterprise 호스트는 `--github-host` 또는 `JIG_GITHUB_HOST`로 지정할 수 있습니다.
- 로컬 git user 설정:
  - `--configure-git-user`를 사용하면 `user.name`, `user.email`을 입력 받아 `git config --local`에 저장합니다.
  - `--git-user-name`, `--git-user-email` 또는 `JIG_GIT_USER_NAME`, `JIG_GIT_USER_EMAIL`을 사용하면 비대화식으로 저장합니다.
- Repository context 확인:
  - `gh repo view --json visibility,viewerPermission`으로 repository visibility와 현재 `gh` 계정 권한을 확인합니다.
- `develop` 브랜치 보장:
  - GitHub에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 생성합니다.
  - 이미 존재하는 `develop` 브랜치는 변경하지 않습니다.
- Branch protection 안내:
  - `install.sh`는 branch protection을 직접 적용하지 않습니다.
  - `GUIDE` 출력이 남은 수동 설정을 안내합니다.

## branch protection (선택)

**branch protection은 선택 기능입니다.** GitHub는 public 저장소에 모든 플랜에서 이 기능을 주지만 **private 저장소는 유료 플랜(Pro·Team·Enterprise)이 있어야** 합니다. 무료 플랜의 private 저장소에서는 protection API도 rulesets API도 `403`을 돌려줍니다. 개인 프로젝트 대부분이 여기에 해당하며 이건 결함이 아니라 플랜의 경계입니다.

그래서 `github-sync`는 조용히 적용하지 않습니다.

1. `gh api repos/<owner>/<repo>`로 `private`와 `permissions.admin`을 확인합니다.
2. 적용할 수 없는 저장소면 한 줄 로그를 남기고 넘어갑니다. 실패로 처리하지 않습니다.
3. 적용할 수 있으면 **한 번 묻습니다** — "이 저장소는 public이거나 해당 플랜이라 `main`·`develop`을 보호할 수 있습니다. 지금 설정할까요?"
4. 대답은 `git config --local jig.branchProtection`에 `enabled` 또는 `skipped`로 남습니다. 다음 sync는 다시 묻지 않습니다. 이 값은 `.git/config`에 있어 clone에는 전달되지 않으므로 다른 사람은 자기 머신에서 따로 답합니다.

`jig-doctor`도 같은 기준으로 읽습니다. `403`은 "플랜 밖"이라 결함이 아닙니다. `404`인데 `skipped`가 기록돼 있으면 "사용자가 안 하기로 함"입니다. 둘 다 권장 조치를 만들지 않습니다.

**보호를 걸지 않으면 로컬 `pre-push` 가드가 유일한 방어선입니다.** 두 스킬 모두 이 사실을 보고에 적습니다.

jig는 ruleset을 만들거나 고치지 않습니다. 이미 ruleset으로 보호된 저장소는 그대로 두고 보호된 것으로 보고합니다.

### 적용되는 정책

`main`과 `develop` 모두 force push와 branch deletion을 금지합니다.

`main`과 `develop`에 같은 정책: Pull Request 불필요, required status check 없음. `develop`에도 같은 body로 `branches/develop/protection`에 적용합니다.

```bash
gh api -X PUT "repos/<owner>/<repo>/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
EOF
```

## 중단되는 경우

GitHub 프로필을 명시한 설치에서는 해당 프로필의 `gh auth login` 또는 credential 검증을 완료하지 못하면 중단합니다. 프로필을 아예 지정하지 않은 설치는 중단하지 않습니다.

## 건너뛰는 경우

installer는 다음 상황에서 GitHub Repository 설정 작업을 건너뛰고 파일 설치를 계속합니다.

- `--scope global`을 사용한 경우
- `--dry-run`을 사용한 경우
- GitHub 프로필을 아직 설정하지 않은 경우
- `gh`가 설치되어 있지 않은 경우
- `git`이 설치되어 있지 않은 경우
- 현재 디렉터리가 git repository가 아닌 경우
- `gh repo view`가 현재 repository를 해석할 수 없는 경우
- 인증된 사용자에게 branch 생성 권한이 없는 경우

## Safety Boundaries

`install.sh`는 다음 작업을 하지 않습니다.

- 라벨을 생성하거나 삭제하지 않습니다.
- 브랜치를 수동으로 삭제하지 않습니다.
- 기존 브랜치를 이동하거나 덮어쓰지 않습니다.
- 릴리스나 태그를 생성하지 않습니다.
- Force push를 하지 않습니다.
- 기본 브랜치를 변경하지 않습니다.
- Repository visibility 또는 ownership을 변경하지 않습니다.

## 레거시 정리

이전 버전의 jig는 release-drafter 기반 PR flow를 설치했습니다. 다음 항목이 남아 있으면 더 이상 사용되지 않으므로 `github-sync` 스킬로 확인 후 정리할 수 있습니다.

- `.github/drafter-config.yaml`
- `.github/workflows/drafter.yaml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- 라벨: `patch`, `minor`, `major`, `enhancement`, `fix`, `chore`
- Repository General 설정 `Automatically delete head branches` (PR을 쓰지 않으므로 효과 없음)

## 검증

파일이나 GitHub 설정을 수정하지 않고 예정 작업만 보려면 dry-run mode를 사용합니다.

```bash
sh install.sh --target codex --scope project --dry-run
```

위 명령은 프로필 없이 스킬 설치 계획을 검증합니다. 설치 후 `jig-setup`을 실행하면 프로필을 선택하고 `develop` 브랜치와 branch protection을 수렴합니다. 설치 중 GitHub 연동까지 하려면 선택적으로 다음처럼 프로필을 전달할 수 있습니다.

```bash
sh install.sh --target codex --scope project --github-profile your-account
```

## 로컬 pre-push 가드

서버측 branch protection과 별개로, `github-sync`가 `.git/hooks/pre-push`에 로컬 가드를 설치합니다. clone마다 로컬에만 존재하므로 새 clone에서는 `github-sync`를 다시 실행해야 합니다.

- `main`/`develop` 대상 force push(non-fast-forward) 차단
- `main`/`develop` 원격 삭제 차단
- `develop:main` fast-forward(릴리즈) 이외의 `main` 직접 push 차단

`--no-verify`로 우회할 수 있는 것이 git hook의 한계입니다. jig 스킬은 우회를 금지합니다. Claude Code에서는 `jig` 플러그인의 PreToolUse hook이 `--no-verify`를 포함한 위반 push 명령을 실행 전에 차단합니다. 저장소가 보호를 걸 수 있으면 서버측 branch protection이 최종 방어선이고, 걸 수 없으면 이 로컬 가드가 유일한 방어선입니다. 진단은 `jig-doctor`, 재설치·갱신은 `github-sync`가 담당합니다.
