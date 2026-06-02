# GitHub Repository Settings

SPAI project scope 설치는 `gh`가 설치 및 인증되어 있고 현재 디렉터리가 GitHub repository에 연결된 git repository일 때 일부 GitHub Repository 설정을 동기화할 수 있습니다.

## install.sh가 적용하는 항목

`install.sh --scope project`는 Agent 스킬/룰 파일과 Release Drafter YAML 파일을 먼저 설치한 뒤, 가능한 경우 다음 GitHub 작업을 시도합니다.

- 표준 6개 라벨 생성 또는 업데이트:
  - `patch`
  - `minor`
  - `major`
  - `enhancement`
  - `fix`
  - `chore`
- Repository General 설정 활성화:
  - Automatically delete head branches
- `main` branch protection 적용:
  - Pull request가 필요합니다.
  - Linear history는 요구하지 않습니다.
  - Force push를 비활성화합니다.
  - Branch deletion을 비활성화합니다.
  - Conversation resolution을 요구합니다.
  - `update_release_draft` check가 이미 `main`에 존재하면 required check로 설정합니다.
- `develop` branch protection 적용:
  - Pull request가 필요합니다.
  - Force push를 비활성화합니다.
  - Branch deletion을 비활성화합니다.
  - Conversation resolution을 요구합니다.

## 건너뛰는 경우

installer는 다음 상황에서 GitHub Repository 설정 작업을 건너뛰고 파일 설치를 계속합니다.

- `--scope global`을 사용한 경우
- `--dry-run`을 사용한 경우
- `gh`가 설치되어 있지 않은 경우
- `gh` 인증이 되어 있지 않은 경우
- `git`이 설치되어 있지 않은 경우
- 현재 디렉터리가 git repository가 아닌 경우
- `gh repo view`가 현재 repository를 해석할 수 없는 경우
- 인증된 사용자에게 repository 설정 또는 branch protection 수정 권한이 없는 경우

## Safety Boundaries

`install.sh`는 다음 작업을 하지 않습니다.

- 표준 6개 외의 라벨을 삭제하지 않습니다.
- 브랜치를 수동으로 삭제하지 않습니다.
- 릴리스나 태그를 생성하지 않습니다.
- PR을 생성하거나 병합하지 않습니다.
- Force push를 하지 않습니다.
- 기본 브랜치를 변경하지 않습니다.
- Repository visibility 또는 ownership을 변경하지 않습니다.

Repository plan 또는 권한 제한 때문에 branch protection을 적용할 수 없는 경우 installer는 warning을 출력하고 계속 진행합니다.

## 검증

파일이나 GitHub 설정을 수정하지 않고 예정 작업만 보려면 dry-run mode를 사용합니다.

```bash
sh install.sh --target all --scope project --dry-run
```

GitHub에 연결된 git repository 안에서 project scope로 실행하면 라벨, repository settings, branch protection을 적용하고 가능한 범위에서 검증합니다.

```bash
sh install.sh --target all --scope project
```
