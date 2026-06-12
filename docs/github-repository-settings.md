# GitHub Repository Settings

SPAI project scope 설치는 `--github-account` 또는 `SPAI_GITHUB_ACCOUNT`로 지정한 `gh` 계정을 사용합니다. 해당 계정이 로그인되어 있지 않으면 `gh auth login`을 실행하고, 로그인되어 있으면 active account가 맞는지 검증합니다. `gh`가 설치되어 있고 현재 디렉터리가 GitHub repository에 연결된 git repository일 때 일부 GitHub Repository 설정을 동기화할 수 있습니다.

## Repository 운영 규칙

- 일반 변경은 현재 `origin/develop`에서 `feature/*`, `fix/*`, `chore/*` 브랜치를 생성하고, 원격 push 후 GitHub PR로 `develop`에 병합합니다.
- 릴리즈는 사용자가 명시적으로 요청한 경우에만 진행하며, 모든 변경이 `develop`에 PR로 병합된 뒤 현재 `origin/develop`에서 `release/vX.Y.Z` 브랜치를 생성하고 GitHub PR로 `main`에 병합합니다.
- 릴리즈 요청 안에 아직 `develop`에 병합되지 않은 코드, 설정, 문서, 생성된 `dist`, workflow 변경이 있으면 릴리즈를 중단하고 먼저 일반 변경 PR 플로우를 완료합니다.
- `release/*` 브랜치에는 일반 작업 변경을 직접 커밋하지 않습니다.

## install.sh가 적용하는 항목

`install.sh --scope project --github-account <account>`는 Agent 스킬/룰 파일, PR template, Release Drafter YAML 파일을 먼저 설치한 뒤, 가능한 경우 다음 GitHub 작업을 시도합니다.

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
- 표준 6개 라벨 생성 또는 업데이트 후, 표준 외 라벨 삭제:
  - `patch`
  - `minor`
  - `major`
  - `enhancement`
  - `fix`
  - `chore`
  - 위 6개에 없는 기존 라벨은 삭제됩니다.
- Release Drafter 릴리즈 노트 형식:
  - `Changes` 하위에 `🚀 Enhancements`, `🐛 Fixes`, `🧰 Chores`, `Summary` 순으로 출력합니다.
  - 변경 카테고리 섹션 사이에는 Markdown horizontal rule을 넣습니다.
  - `patch`, `minor`, `major`는 버전 계산에만 사용하고 `Version Updates` 카테고리로 출력하지 않습니다.
  - `develop` 대상 PR 중 `enhancement`, `fix`, `chore` 라벨이 있는 PR의 `## Summary` bullet을 취합해 `Summary` 섹션에 추가합니다.
  - `Summary` bullet에서는 파일명, 설정 키, 라벨, 브랜치명, workflow 이름처럼 강조할 기술 용어를 backtick으로 감쌉니다.
  - `Contributors`는 GitHub가 별도로 노출하므로 릴리즈 본문에는 명시적으로 출력하지 않습니다.
- Repository General 설정 활성화:
  - Automatically delete head branches
- GitHub Actions Workflow permissions 설정:
  - Read and write permissions
- `develop` 브랜치 보장:
  - GitHub에 `develop` 브랜치가 없으면 `main`의 현재 commit에서 생성합니다.
  - 이미 존재하는 `develop` 브랜치는 변경하지 않습니다.
- Branch protection 안내:
  - `install.sh`는 branch protection을 직접 적용하지 않습니다.
  - `GUIDE` 출력이 남은 수동 설정을 안내합니다.

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
- 인증된 사용자에게 branch 생성 또는 repository 설정 수정 권한이 없는 경우

## Safety Boundaries

`install.sh`는 다음 작업을 하지 않습니다.

- 표준 6개 라벨 자체를 삭제하지 않습니다.
- 브랜치를 수동으로 삭제하지 않습니다.
- 기존 브랜치를 이동하거나 덮어쓰지 않습니다.
- GitHub Actions의 pull request review 승인 권한 설정은 변경하지 않습니다.
- 릴리스나 태그를 생성하지 않습니다.
- PR을 생성하거나 병합하지 않습니다.
- Force push를 하지 않습니다.
- 기본 브랜치를 변경하지 않습니다.
- Repository visibility 또는 ownership을 변경하지 않습니다.

## 검증

파일이나 GitHub 설정을 수정하지 않고 예정 작업만 보려면 dry-run mode를 사용합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1 --dry-run
```

GitHub에 연결된 git repository 안에서 project scope로 실행하면 지정한 `gh` 계정으로 표준 6개 라벨만 남도록 라벨을 정리하고, GitHub Actions workflow permissions를 read and write로 맞추며, `develop` 브랜치가 없으면 생성하고, repository settings를 동기화한 뒤 가능한 범위에서 검증합니다. branch protection은 `GUIDE`로 수동 안내합니다.

```bash
sh install.sh --target all --scope project --github-account 0x0w1
```
