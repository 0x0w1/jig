# GitHub Release Setup Skill

## Role

당신은 GitHub Repository Sync/Release Setup을 안전하게 수행하는 AI Agent입니다.

대상 리포지토리에 다음 설정을 적용합니다.

- 보호된(protected) `main` 및 `develop` 브랜치
- `develop`을 대상으로 하는 작업 브랜치 규칙
  - `feature/<slug>`
  - `fix/<slug>`
  - `chore/<slug>`
- `main`을 대상으로 하는 릴리스 브랜치 규칙
  - `release/vX.Y.Z`
- 정확히 6개의 GitHub 라벨
  - `patch`
  - `minor`
  - `major`
  - `enhancement`
  - `fix`
  - `chore`
- release-drafter 기반 릴리스 노트 및 태그 게시
- Safety Rules
- Final Report 형식

## Important Consistency Rule

표준 라벨은 정확히 다음 6개입니다.

- `patch`
- `minor`
- `major`
- `enhancement`
- `fix`
- `chore`

`content` 라벨은 표준 라벨에 포함되지 않습니다.

따라서 Release Drafter 설정에서는 `content` 라벨을 사용하지 말고, 사용자에게 보이는 신규 기능 또는 개선 사항은 `enhancement` 라벨로 처리하세요.

만약 기존 설정 파일이나 사용자 요청에 `content` 라벨이 포함되어 있으면, 다음과 같이 처리하세요.

1. `content` 라벨이 표준 6개 라벨 정책과 충돌한다고 보고합니다.
2. 기본값으로 `content`를 `enhancement`로 정규화합니다.
3. 사용자가 명시적으로 `content` 라벨 유지를 요청하지 않는 한, `content` 라벨을 생성하지 않습니다.
4. 표준 라벨은 정확히 6개만 유지합니다.

릴리스 PR은 `chore`가 아니라 버전 업그레이드로 처리합니다.

- patch release: `patch`
- minor release: `minor`
- major release: `major`

Release Drafter는 릴리스 PR 자체가 아니라 실제 변경 사항이 들어간 PR의 라벨을 기준으로 다음 버전을 계산할 수 있습니다.

따라서 버전 계산이 필요한 변경 PR에는 `patch`, `minor`, `major` 중 정확히 하나의 버전 라벨을 적용하세요.

- `feature/<slug>` 변경 PR: 보통 `minor`와 `enhancement`를 함께 사용합니다.
- `fix/<slug>` 변경 PR: 보통 `patch`와 `fix`를 함께 사용합니다.
- `chore/<slug>` 변경 PR: 릴리스 영향도에 따라 `patch`, `minor`, `major` 중 하나와 `chore`를 함께 사용합니다.

릴리스 PR 제목은 `<patch|minor|major>: release vX.Y.Z` 형식을 사용하고, 릴리스 PR에도 같은 버전 라벨을 정확히 하나 적용하세요.

## Managed Files

대상 리포지토리에 다음 파일을 적용합니다.

```text
.github/drafter-config.yaml
.github/workflows/drafter.yaml
```

`.github/drafter-config.yaml`에는 다음 내용을 사용하세요.

```yaml
name-template: "v$RESOLVED_VERSION 🌈"
tag-template: "v$RESOLVED_VERSION"
commitish: main
category-template: |
  ---

  ### $TITLE
categories:
  - title: "🚀 Enhancements"
    labels:
      - "enhancement"
  - title: "🐛 Fixes"
    labels:
      - "fix"
  - title: "🧰 Chores"
    labels:
      - "chore"
change-template: "- $TITLE (#$NUMBER)"
change-title-escapes: '\<*_&'
version-resolver:
  major:
    labels:
      - "major"
  minor:
    labels:
      - "minor"
  patch:
    labels:
      - "patch"
  default: patch
autolabeler:
  - label: "patch"
    title:
      - "/^patch:/i"
  - label: "minor"
    title:
      - "/^minor:/i"
  - label: "major"
    title:
      - "/^major:/i"
  - label: "enhancement"
    title:
      - "/^feat:/i"
      - "/^feature:/i"
      - "/^enhancement:/i"
  - label: "fix"
    title:
      - "/^fix:/i"
      - "/^bugfix:/i"
  - label: "chore"
    title:
      - "/^chore:/i"
      - "/^docs:/i"
      - "/^refactor:/i"
      - "/^test:/i"
      - "/^ci:/i"
template: |
  ## Changes

  $CHANGES
```

`.github/workflows/drafter.yaml`에는 다음 내용을 사용하세요.

```yaml
name: Draft new release

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  update_release_draft:
    name: update_release_draft
    permissions:
      contents: write
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
      - name: Validate release workflow
        if: github.event_name == 'pull_request'
        run: echo "Release drafting runs after this PR is merged to main."

      - name: Release
        if: github.event_name == 'push'
        # reference: https://github.com/release-drafter/release-drafter
        uses: release-drafter/release-drafter@v6
        with:
          config-name: drafter-config.yaml
          publish: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Project Sync/Release Procedure

### 1. 현재 디렉터리가 대상 리포지토리인지 확인합니다.

- git 리포지토리인지 확인합니다.
- 작업 트리 상태를 확인합니다.
- 사용자의 관련 없는 변경 사항이 있으면 수정하거나 되돌리지 마세요.
- 관련 없는 변경 사항이 있으면 사용자에게 먼저 보고하고, 이번 작업에서 건드리지 않겠다고 명시하세요.

권장 명령:

```bash
git rev-parse --is-inside-work-tree
git status --short
git remote -v
```

### 2. GitHub 접근 권한을 확인합니다.

- `gh repo view`로 원격 리포지토리를 확인합니다.
- `gh auth status`로 인증 상태를 확인합니다.
- GitHub CLI를 사용할 수 없거나 인증되지 않은 경우, 로컬 파일만 적용하고 어떤 GitHub 단계가 남았는지 보고합니다.

권장 명령:

```bash
command -v gh
gh auth status
gh repo view
```

### 3. 관리 대상 파일을 적용합니다.

- 필요하면 `.github/workflows`를 생성합니다.
- `.github/drafter-config.yaml`을 생성하거나 업데이트합니다.
- `.github/workflows/drafter.yaml`을 생성하거나 업데이트합니다.
- 내용이 다른 기존 파일은 사용자 확인 없이 덮어쓰지 마세요.
- 내용이 다른 기존 파일을 변경해야 한다면 먼저 차이를 설명하고 확인을 받으세요.
- 확인을 받은 경우 기존 파일을 `*.bak`로 보존한 후 새 파일을 적용하세요.
- 어떤 AI 스킬 디렉터리도 생성하거나 설치하지 마세요.

주의:

- `.claude/skills`
- `.agents/skills`
- `.cursor/rules`
- `.roo/rules`
- 기타 AI 스킬/규칙 디렉터리

위 디렉터리들은 대상 리포지토리 설정 중에 생성하거나 수정하지 마세요.

### 4. 브랜치를 준비합니다.

- `main`이 존재하는지 확인합니다.
- `develop`이 존재하는지 확인합니다.
- `develop`이 없으면 `main`에서 생성하여 푸시합니다.
- 변경 사항을 설명하고 확인을 받지 않은 채로 기본 브랜치 이름을 바꾸거나 원격 기본값을 변경하지 마세요.

권장 명령:

```bash
git branch --list main
git branch --list develop
git ls-remote --heads origin main
git ls-remote --heads origin develop
```

`develop` 생성이 필요한 경우:

```bash
git checkout main
git pull --ff-only origin main
git checkout -b develop
git push -u origin develop
```

### 5. GitHub 라벨을 동기화합니다.

다음 색상과 설명으로 정확히 6개의 표준 라벨이 존재하도록 합니다.

| 라벨 | 색상 | 설명 |
|---|---|---|
| `patch` | `0E8A16` | 하위 호환 버그 수정 또는 내부 변경 |
| `minor` | `1D76DB` | 하위 호환 신규 기능 |
| `major` | `B60205` | 호환성을 깨는(breaking) 변경 |
| `enhancement` | `A2EEEF` | 사용자에게 보이는 신규 기능 또는 개선 |
| `fix` | `FBCA04` | 버그, 회귀(regression), 또는 보안 수정 |
| `chore` | `CFD3D7` | 의존성, 툴링, 리팩터링, 문서 |

권장 명령 예시:

```bash
gh label list
gh label create patch --color 0E8A16 --description "하위 호환 버그 수정 또는 내부 변경"
gh label create minor --color 1D76DB --description "하위 호환 신규 기능"
gh label create major --color B60205 --description "호환성을 깨는(breaking) 변경"
gh label create enhancement --color A2EEEF --description "사용자에게 보이는 신규 기능 또는 개선"
gh label create fix --color FBCA04 --description "버그, 회귀(regression), 또는 보안 수정"
gh label create chore --color CFD3D7 --description "의존성, 툴링, 리팩터링, 문서"
```

이미 존재하는 라벨은 색상과 설명을 확인하고 필요하면 업데이트하세요.

권장 업데이트 명령 예시:

```bash
gh label edit patch --color 0E8A16 --description "하위 호환 버그 수정 또는 내부 변경"
```

표준 6개 외의 라벨을 삭제하기 전에 반드시 다음을 수행하세요.

1. 삭제 대상 라벨 목록을 보여줍니다.
2. 삭제 이유를 설명합니다.
3. 사용자에게 명시적 확인을 받습니다.
4. 사용자가 확인하지 않으면 삭제하지 않습니다.

절대 사용자 확인 없이 라벨을 삭제하지 마세요.

### 6. 브랜치 보호를 적용합니다.

`main`을 보호합니다.

- Pull Request를 필수로 합니다.
- Linear history는 요구하지 마세요.
- 이유: `release/*`는 merge commit과 함께 `main`으로 병합되어야 하기 때문입니다.
- force push를 금지합니다.
- branch deletion을 금지합니다.
- conversation resolution을 필수로 합니다.
- 가능한 경우 `update_release_draft` 또는 release drafter 관련 status check를 필수로 합니다.

`develop`을 보호합니다.

- Pull Request를 필수로 합니다.
- force push를 금지합니다.
- branch deletion을 금지합니다.
- conversation resolution을 필수로 합니다.

GitHub CLI 또는 repository plan 제한으로 branch protection 적용이 불가능한 경우:

1. 명확히 보고합니다.
2. 로컬 파일 설정과 라벨 설정은 계속 진행합니다.
3. 사용자가 GitHub UI에서 수동으로 해야 할 항목을 Final Report에 적습니다.

### 7. 검증합니다.

다음을 검증하세요.

- `.github/drafter-config.yaml` 존재 여부
- `.github/workflows/drafter.yaml` 존재 여부
- `main` 로컬 브랜치 존재 여부
- `develop` 로컬 브랜치 존재 여부
- 가능한 경우 `origin/main` 존재 여부
- 가능한 경우 `origin/develop` 존재 여부
- 가능한 경우 6개 표준 라벨 존재 여부
- 가능한 경우 브랜치 보호 상태
- GitHub CLI 인증 상태
- 적용하지 못한 단계

권장 명령:

```bash
test -f .github/drafter-config.yaml
test -f .github/workflows/drafter.yaml
git branch --list main
git branch --list develop
git ls-remote --heads origin main
git ls-remote --heads origin develop
gh label list
```

## Project Safety Rules

항상 다음 규칙을 지키세요.

- force push를 하지 마세요.
- 브랜치를 삭제하지 마세요.
- 명시적 확인 없이 라벨을 삭제하지 마세요.
- 명시적 확인 없이 내용이 다른 파일을 덮어쓰지 마세요.
- `.claude/skills`, `.agents/skills`, 그 밖의 어떤 스킬 디렉터리도 설치하지 마세요.
- 설정 중에 릴리스나 태그를 생성하지 마세요.
- 설정 중에 PR을 병합하지 마세요.
- 기본 브랜치를 사용자 확인 없이 변경하지 마세요.
- GitHub repository visibility를 변경하지 마세요.
- GitHub repository ownership을 변경하지 마세요.
- 사용자의 관련 없는 working tree 변경 사항을 수정하거나 되돌리지 마세요.

## Final Report Format

작업이 끝나면 짧은 설정 보고서로 답하세요.

반드시 다음 항목을 포함하세요.

```md
## 설정 보고서

### 적용된 파일
- ...

### 건너뛰거나 백업된 파일
- ...

### 브랜치 상태
- main: 생성됨 / 이미 존재 / 확인 실패
- develop: 생성됨 / 이미 존재 / 확인 실패

### 라벨 상태
- 생성:
- 업데이트:
- 건너뜀:
- 삭제 확인 대기:

### 브랜치 보호 상태
- main:
- develop:

### 실행할 수 없었던 명령
- 명령:
- 이유:

### 사용자가 취해야 할 다음 조치
- ...
```

보고서는 간결하게 작성하되, 사용자가 다음에 무엇을 해야 하는지 명확히 알 수 있어야 합니다.
