# GitHub Repository Settings

SPAI project scope 설치는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 `gh` 계정을 사용합니다. 해당 계정이 로그인되어 있지 않으면 `gh auth login`을 실행하고, 로그인되어 있으면 active account가 맞는지 검증합니다. `gh`가 설치되어 있고 현재 디렉터리가 GitHub repository에 연결된 git repository일 때 일부 GitHub Repository 설정을 동기화할 수 있습니다.

## install.sh가 적용하는 항목

`install.sh --scope project --github-account <account>`는 Agent 스킬/룰 파일과 Release Drafter YAML 파일을 먼저 설치한 뒤, 가능한 경우 다음 GitHub 작업을 시도합니다.

- GitHub CLI 계정 선택:
  - `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 입력 받은 계정을 사용합니다.
  - 입력 받은 계정이 `gh`에 없으면 `gh auth login`을 실행합니다.
  - GitHub 작업 전에 `gh auth switch --user <account>`를 실행하고 active account를 검증합니다.
  - GitHub Enterprise 호스트는 `--github-host` 또는 `SPAI_GITHUB_HOST`로 지정할 수 있습니다.
- 로컬 git user 설정:
  - `--configure-git-user`를 사용하면 `user.name`, `user.email`을 입력 받아 `git config --local`에 저장합니다.
  - `--git-user-name`, `--git-user-email` 또는 `SPAI_GIT_USER_NAME`, `SPAI_GIT_USER_EMAIL`을 사용하면 비대화식으로 저장합니다.
- Branch protection은 GitHub Rulesets가 아니라 classic branch protection으로 생성합니다.
- Repository context 확인:
  - `gh repo view --json visibility,viewerPermission`으로 repository visibility와 현재 `gh` 계정 권한을 확인합니다.
  - private repository이면 classic branch protection에 GitHub plan 지원과 repository rules 수정 권한이 필요할 수 있음을 warning으로 출력합니다.
- 표준 6개 라벨 생성 또는 업데이트 후, 표준 외 라벨 삭제:
  - `patch`
  - `minor`
  - `major`
  - `enhancement`
  - `fix`
  - `chore`
  - 위 6개에 없는 기존 라벨은 삭제됩니다.
- Repository General 설정 활성화:
  - Automatically delete head branches
- `develop` 브랜치 보장:
  - GitHub에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 생성합니다.
  - 이미 존재하는 `develop` 브랜치는 변경하지 않습니다.
- `main` classic branch protection 적용:
  - Pull request가 필요합니다.
  - Required status checks는 사용하지 않습니다.
  - Linear history는 요구하지 않습니다.
  - Force push를 비활성화합니다.
  - Branch deletion을 비활성화합니다.
  - Conversation resolution을 요구합니다.
- `develop` classic branch protection 적용:
  - Pull request가 필요합니다.
  - Required status checks는 사용하지 않습니다.
  - Force push를 비활성화합니다.
  - Branch deletion을 비활성화합니다.
  - Conversation resolution을 요구합니다.

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
- 인증된 사용자에게 branch 생성, repository 설정 또는 branch protection 수정 권한이 없는 경우

Branch protection 적용이 실패하면 installer는 다음 정보를 warning으로 출력하고 계속 진행합니다.

- 대상 branch
- repository slug
- repository visibility
- 현재 `gh` 계정의 repository permission
- `gh api`가 반환한 GitHub API 오류

## Safety Boundaries

`install.sh`는 다음 작업을 하지 않습니다.

- 표준 6개 라벨 자체를 삭제하지 않습니다.
- 브랜치를 수동으로 삭제하지 않습니다.
- 기존 브랜치를 이동하거나 덮어쓰지 않습니다.
- 릴리스나 태그를 생성하지 않습니다.
- PR을 생성하거나 병합하지 않습니다.
- Force push를 하지 않습니다.
- 기본 브랜치를 변경하지 않습니다.
- Repository visibility 또는 ownership을 변경하지 않습니다.

Repository plan 또는 권한 제한 때문에 branch protection을 적용할 수 없는 경우 installer는 warning을 출력하고 계속 진행합니다. GitHub protected branches는 public repository에서는 GitHub Free에서도 사용할 수 있지만, private repository에서는 GitHub Pro, Team, Enterprise Cloud, 또는 Enterprise Server 등 protected branches를 지원하는 plan이 필요합니다.

## 검증

파일이나 GitHub 설정을 수정하지 않고 예정 작업만 보려면 dry-run mode를 사용합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 --dry-run
```

GitHub에 연결된 git repository 안에서 project scope로 실행하면 지정한 `gh` 계정으로 표준 6개 라벨만 남도록 라벨을 정리하고, `develop` 브랜치가 없으면 생성하며, repository settings, branch protection을 적용한 뒤 가능한 범위에서 검증합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1
```
