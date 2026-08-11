# GitHub Release Setup Skill

## Role

당신은 GitHub Repository Sync/Release Setup을 안전하게 수행하는 AI Agent입니다.

대상 리포지토리에 다음 설정을 적용합니다.

- force push와 branch deletion이 금지된 `main` 및 `develop` 브랜치 (직접 push는 허용)
- `develop`을 기준으로 하는 작업 브랜치 규칙
  - `feature/<slug>`
  - `fix/<slug>`
  - `chore/<slug>`
- 작업 브랜치를 `develop`에 로컬 squash merge로 병합하는 규칙 (Pull Request 없음)
- CLI 기반 릴리스 규칙: `develop`을 `main`으로 fast-forward push하고, `vX.Y.Z` 태그와 GitHub 릴리스를 CLI에서 생성
- Safety Rules
- Final Report 형식

## Flow Profiles

SPAI는 두 가지 작업 flow 프로필을 지원합니다. 릴리스 절차는 두 flow 모두 동일하게 CLI 기반입니다.

- `solo-cli` (기본): 작업 브랜치를 `develop`에 로컬 `git merge --squash`로 병합하고 직접 push합니다. `develop`은 PR을 필수로 하지 않습니다.
- `team-pr`: 작업 브랜치를 push하고 `develop` 대상 Pull Request를 squash merge로 병합합니다. `develop`은 PR을 필수로 보호합니다.

## Release Model

이 설정은 release-drafter를 사용하지 않습니다.

- 일상 작업: `origin/develop`에서 작업 브랜치를 만들고, 선택한 flow 프로필에 따라 `develop`에 병합합니다 (`solo-cli`: 로컬 `git merge --squash` 후 push).
- squash 커밋 제목은 conventional prefix를 사용합니다: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`.
- 릴리스: `git push origin develop:main`(fast-forward만 허용) 후 `git tag vX.Y.Z`와 `gh release create`로 태그·릴리스를 생성합니다.
- 다음 버전은 최신 `vX.Y.Z` 태그에서 bump 타입(`patch`/`minor`/`major`)으로 계산합니다. 기본값은 `patch`입니다.
- 릴리스 노트는 `<이전 태그>..<새 태그>` 커밋 로그를 기반으로 에이전트가 직접 작성합니다.
  - `feat:` → `🚀 Enhancements`
  - `fix:` → `🐛 Fixes`
  - 그 외 → `🧰 Chores`
  - `### Summary`: 커밋 제목과 본문을 바탕으로 사용자 관점 한국어 불릿 요약

GitHub 라벨과 PR 템플릿은 이 flow에서 사용하지 않으므로 동기화하지 않습니다.

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
- GitHub CLI를 사용할 수 없거나 인증되지 않은 경우, 로컬 단계만 적용하고 어떤 GitHub 단계가 남았는지 보고합니다.

권장 명령:

```bash
command -v gh
gh auth status
gh repo view
```

### 3. 브랜치를 준비합니다.

- `main`이 존재하는지 확인합니다.
- `develop`이 존재하는지 확인합니다.
- `develop`이 없으면 `main`에서 생성하여 푸시합니다.
- 변경 사항을 설명하고 확인을 받지 않은 채로 기본 브랜치 이름을 바꾸거나 원격 기본값을 변경하지 마세요.
- 어떤 AI 스킬 디렉터리도 생성하거나 설치하지 마세요 (`.claude/skills`, `.agents/skills`, `.cursor/rules`, `.roo/rules` 등).

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

### 4. 브랜치 보호를 적용합니다.

두 flow 모두 force push와 branch deletion을 금지합니다. PR 필수 여부만 flow에 따라 다릅니다.

- `solo-cli`: `main`과 `develop` 모두 Pull Request를 필수로 하지 않습니다. 이유: 작업 병합과 릴리스 승격 모두 CLI에서 직접 push로 수행되기 때문입니다.
- `team-pr`: `develop`은 Pull Request를 필수로 하고(squash merge), `main`은 릴리스 fast-forward push를 위해 PR을 필수로 하지 않습니다.
- required status check는 저장소가 별도로 정의하지 않는 한 요구하지 않습니다.

권장 명령 예시:

```bash
gh api -X PUT "repos/<owner>/<repo>/branches/main/protection" --input protection.json
gh api -X PUT "repos/<owner>/<repo>/branches/develop/protection" --input protection.json
```

`protection.json` 예시:

```json
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
```

GitHub CLI 또는 repository plan 제한으로 branch protection 적용이 불가능한 경우:

1. 명확히 보고합니다.
2. 나머지 로컬 단계는 계속 진행합니다.
3. 사용자가 GitHub UI에서 수동으로 해야 할 항목을 Final Report에 적습니다.

### 5. 레거시 release-drafter 설정을 정리합니다.

대상 리포지토리에 다음 파일이 남아 있으면 제거 대상으로 보고하고, 사용자 확인 후에만 삭제합니다.

```text
.github/drafter-config.yaml
.github/workflows/drafter.yaml
.github/PULL_REQUEST_TEMPLATE.md
```

이전 flow에서 사용하던 라벨(`patch`, `minor`, `major`, `enhancement`, `fix`, `chore`)이 남아 있으면 삭제 후보로 보고만 하고, 명시적 확인 없이 삭제하지 마세요.

### 6. 검증합니다.

다음을 검증하세요.

- `main` 로컬 브랜치 존재 여부
- `develop` 로컬 브랜치 존재 여부
- 가능한 경우 `origin/main` 존재 여부
- 가능한 경우 `origin/develop` 존재 여부
- 가능한 경우 브랜치 보호 상태 (force push·deletion 금지, PR 필수 아님)
- 레거시 release-drafter 파일 존재 여부
- GitHub CLI 인증 상태
- 적용하지 못한 단계

권장 명령:

```bash
git branch --list main
git branch --list develop
git ls-remote --heads origin main
git ls-remote --heads origin develop
gh api "repos/<owner>/<repo>/branches/main/protection"
```

## Project Safety Rules

항상 다음 규칙을 지키세요.

- force push를 하지 마세요.
- 브랜치를 삭제하지 마세요.
- 명시적 확인 없이 라벨이나 파일을 삭제하지 마세요.
- 명시적 확인 없이 내용이 다른 파일을 덮어쓰지 마세요.
- `.claude/skills`, `.agents/skills`, 그 밖의 어떤 스킬 디렉터리도 설치하지 마세요.
- 설정 중에 릴리스나 태그를 생성하지 마세요.
- 기본 브랜치를 사용자 확인 없이 변경하지 마세요.
- GitHub repository visibility를 변경하지 마세요.
- GitHub repository ownership을 변경하지 마세요.
- 사용자의 관련 없는 working tree 변경 사항을 수정하거나 되돌리지 마세요.

## Final Report Format

작업이 끝나면 짧은 설정 보고서로 답하세요.

반드시 다음 항목을 포함하세요.

```md
## 설정 보고서

### 브랜치 상태
- main: 생성됨 / 이미 존재 / 확인 실패
- develop: 생성됨 / 이미 존재 / 확인 실패

### 브랜치 보호 상태
- main:
- develop:

### 레거시 정리
- 발견된 release-drafter 파일:
- 삭제 확인 대기 라벨:

### 실행할 수 없었던 명령
- 명령:
- 이유:

### 사용자가 취해야 할 다음 조치
- ...
```

보고서는 간결하게 작성하되, 사용자가 다음에 무엇을 해야 하는지 명확히 알 수 있어야 합니다.
