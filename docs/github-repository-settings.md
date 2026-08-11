# GitHub Repository Settings

SPAI project scope 설치는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 `gh` 계정을 사용합니다. 해당 계정이 로그인되어 있지 않으면 `gh auth login`을 실행하고, 로그인되어 있으면 active account가 맞는지 검증합니다. `gh`가 설치되어 있고 현재 디렉터리가 GitHub repository에 연결된 git repository일 때 일부 GitHub Repository 설정을 동기화할 수 있습니다.

## Repository 운영 규칙

- 일반 변경은 현재 `origin/develop`에서 `feature/*`, `fix/*`, `chore/*` 브랜치를 생성해 작업하고, 완료 후 로컬에서 `git merge --squash`로 `develop`에 병합해 push합니다. Pull Request는 사용하지 않습니다.
- `develop`의 squash 커밋 제목은 conventional prefix(`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`)를 사용합니다.
- 릴리즈는 사용자가 명시적으로 요청한 경우에만 진행하며, `git push origin develop:main`(fast-forward만 허용)으로 `develop`을 `main`으로 승격한 뒤 CLI에서 `vX.Y.Z` 태그와 GitHub 릴리즈를 생성합니다. 릴리즈 PR, `release/*` 브랜치, release-drafter는 사용하지 않습니다.
- 릴리즈 요청 안에 아직 `develop`에 병합되지 않은 코드, 설정, 문서, 생성된 `dist`, 설치 스크립트 변경이 있으면 릴리즈를 중단하고 먼저 일반 작업 flow를 완료합니다.

## install.sh가 적용하는 항목

`install.sh --scope project --github-account <account>`는 Agent 스킬/룰 파일을 먼저 설치한 뒤, 가능한 경우 다음 GitHub 작업을 시도합니다.

- GitHub CLI 계정 선택:
  - `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 입력 받은 계정을 사용합니다.
  - 입력 받은 계정이 `gh`에 없으면 `gh auth login`을 실행합니다.
  - GitHub 작업 전에 `gh auth switch --user <account>`를 실행하고 active account를 검증합니다.
  - GitHub Enterprise 호스트는 `--github-host` 또는 `SPAI_GITHUB_HOST`로 지정할 수 있습니다.
- 로컬 git user 설정:
  - `--configure-git-user`를 사용하면 `user.name`, `user.email`을 입력 받아 `git config --local`에 저장합니다.
  - `--git-user-name`, `--git-user-email` 또는 `SPAI_GIT_USER_NAME`, `SPAI_GIT_USER_EMAIL`을 사용하면 비대화식으로 저장합니다.
- Repository context 확인:
  - `gh repo view --json visibility,viewerPermission`으로 repository visibility와 현재 `gh` 계정 권한을 확인합니다.
- `develop` 브랜치 보장:
  - GitHub에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 생성합니다.
  - 이미 존재하는 `develop` 브랜치는 변경하지 않습니다.
- Branch protection 안내:
  - `install.sh`는 branch protection을 직접 적용하지 않습니다.
  - `GUIDE` 출력이 남은 수동 설정을 안내합니다.

## 권장 branch protection

설치된 `github-sync` 스킬이 flow에 맞는 적용을 대신 수행할 수 있습니다. 두 flow 모두 force push와 branch deletion은 금지합니다.

### solo-cli (기본)

`main`과 `develop`에 같은 정책: Pull Request 불필요, required status check 없음.

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

### team-pr

`develop`은 PR 필수(squash merge), `main`은 릴리즈 fast-forward push를 위해 PR 불필요.

`develop`용:

```bash
gh api -X PUT "repos/<owner>/<repo>/branches/develop/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
EOF
```

## 중단되는 경우

installer는 project scope에서 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`가 없으면 GitHub 작업 계정을 확정할 수 없으므로 즉시 중단합니다.

지정한 GitHub 계정으로 `gh auth login` 또는 `gh auth switch`를 완료하지 못한 경우에도 중단합니다.

## 건너뛰는 경우

installer는 다음 상황에서 GitHub Repository 설정 작업을 건너뛰고 파일 설치를 계속합니다.

- `--scope global`을 사용한 경우
- `--dry-run`을 사용한 경우
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

이전 버전의 SPAI는 release-drafter 기반 PR flow를 설치했습니다. 다음 항목이 남아 있으면 더 이상 사용되지 않으므로 `github-sync` 스킬로 확인 후 정리할 수 있습니다.

- `.github/drafter-config.yaml`
- `.github/workflows/drafter.yaml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- 라벨: `patch`, `minor`, `major`, `enhancement`, `fix`, `chore`
- Repository General 설정 `Automatically delete head branches` (PR을 쓰지 않으므로 효과 없음)

## 검증

파일이나 GitHub 설정을 수정하지 않고 예정 작업만 보려면 dry-run mode를 사용합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 --dry-run
```

GitHub에 연결된 git repository 안에서 project scope로 실행하면 지정한 `gh` 계정으로 로그인/선택을 검증하고, `develop` 브랜치가 없으면 생성한 뒤 가능한 범위에서 검증합니다. branch protection은 `GUIDE`로 수동 안내합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1
```
