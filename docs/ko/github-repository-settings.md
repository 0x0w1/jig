# GitHub Repository Settings

[English](../en/github-repository-settings.md)

이 문서는 `install.sh`(Antigravity CLI 대상)의 GitHub 동작을 설명합니다. Claude Code와 Codex는 플러그인으로 설치되어 installer를 거치지 않으므로 저장소 프로필 설정과 수렴은 설치 후 `/jig:jig-setup`과 `jig:jig-setup`으로 처리합니다.

jig project scope 스킬 설치에는 GitHub 프로필이 필요하지 않습니다. 프로필 없이 설치하면 GitHub Repository 설정 동기화만 건너뜁니다. 설치된 `jig-setup`이 이후 `JIG_GITHUB_PROFILE` 또는 로컬 `jig.githubProfile`을 설정합니다. 프로필 credential은 명령별 환경으로 전달하며 전역 active account를 바꾸지 않습니다.

## Repository 운영 규칙

- 일반 변경은 현재 `origin/develop`에서 `feature/*`, `fix/*`, `chore/*` 브랜치를 생성해 작업하고 완료 후 로컬에서 `git merge --squash`로 `develop`에 병합해 push합니다. Pull Request는 사용하지 않습니다.
- `develop`의 squash 커밋 제목은 conventional prefix(`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`)를 사용합니다.
- 릴리즈는 사용자가 명시적으로 요청한 경우에만 진행합니다. `git push origin develop:main`(fast-forward만 허용)으로 `develop`을 `main`으로 승격한 뒤 CLI에서 `vX.Y.Z` 태그와 GitHub 릴리즈를 생성합니다. 릴리즈 PR, `release/*` 브랜치, release-drafter는 사용하지 않습니다.
- 릴리즈 요청 안에 아직 `develop`에 병합되지 않은 코드, 설정, 문서, 생성된 `dist`, 설치 스크립트 변경이 있으면 릴리즈를 중단하고 먼저 일반 작업 flow를 완료합니다.

## install.sh가 적용하는 항목

`install.sh --target antigravity --scope project`는 Agent 스킬/룰 파일을 먼저 설치합니다. 프로필이 이미 제공된 경우에만 이어서 다음 GitHub 작업을 시도합니다.

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
3. 브랜치별로 분류합니다. 이미 충족된 정책에는 쓰기·질문이 없고 미승인 변경만 묻습니다. 보호된 한 브랜치가 다른 브랜치 변경의 승인이 되지 않습니다. 기존 `skipped`는 유지하며 두 브랜치가 모두 충족하고 skipped 기록이 없을 때만 이미 충족된 `enabled`로 기록합니다.
4. 대답은 `git config --local jig.branchProtection`에 `enabled` 또는 `skipped`로 남습니다. 다음 sync는 다시 묻지 않습니다. 이 값은 `.git/config`에 있어 clone에는 전달되지 않으므로 다른 사람은 자기 머신에서 따로 답합니다.

`jig-doctor`도 같은 기준으로 읽습니다. `403`은 플랜 또는 권한 제한이라 결함이 아닙니다. `404`인데 `skipped`가 기록돼 있으면 "사용자가 안 하기로 함"입니다. 둘 다 권장 조치를 만들지 않고, jig 기준보다 강한 정책도 마찬가지입니다. `jig-doctor`는 required review와 required check를 저장소의 것으로 보고하며 drift로 판정하지 않습니다.

**보호를 걸지 않으면 로컬 `pre-push` 가드가 유일한 방어선입니다.** 두 스킬 모두 이 사실을 보고에 적습니다.

jig는 ruleset을 만들거나 고치지 않습니다. 이미 ruleset으로 보호된 저장소는 그대로 두고 보호된 것으로 보고합니다.

### 적용되는 것

jig가 `main`과 `develop`에 보장하는 것은 **두 가지**입니다. force push 차단과 branch 삭제 차단입니다. Pull Request review도 status check도 요구하지 않습니다.

**요구하지 않는 것과 제거하는 것은 다릅니다.** 이미 승인 2회와 CI 통과를 요구하는 저장소는 sync 후에도 그대로 요구합니다. 그 설정은 jig가 아니라 저장소의 것입니다.

그래서 `github-sync`는 branch의 현재 protection을 먼저 읽고 분류합니다.

```bash
sh scripts/classify-protection.sh --file <response.json>
sh scripts/plan-protection.sh < <response.json>
```

| `verdict` | sync가 하는 일 |
|---|---|
| `absent` | 두 보장을 제안합니다. 보존할 기존 정책이 없습니다 |
| `satisfied` | 아무것도 하지 않습니다. jig 기준이든 더 강한 정책이든 두 보장이 이미 성립합니다 |
| `needs-tightening` | 정책 보존 변환을 계획하고 미지원 데이터는 차단합니다 |
| `unreadable` | 아무것도 바꾸지 않고 보고합니다 |

도구는 저장한 API 응답에 `jq`로 동작하며 HTTP 상태는 따로 보관합니다. 일반 404·인증/호출 한도 오류·불완전한 플래그는 부재가 아니라 해석 불가입니다. `Branch not protected`가 확인돼야 신규 정책을 계획합니다.

요청 생성기는 `none`, PUT용 `body`를 포함한 `update`, body 없는 `blocked`를 반환합니다. 지원되는 review·검사 앱 연결·사용자/팀/앱 제한·플래그를 보존하고 force push·삭제 차단만 바꿉니다. GET 객체를 PUT으로 그대로 보낼 수 없습니다. 알 수 없거나 불완전한 필드, 별도 API가 필요한 서명 설정은 변경을 차단합니다. 요청 생성은 전송 승인이 아닙니다. 승인된 `enabled`를 재사용하고 `skipped`를 유지하며, 전송 전 재조회·전송 후 보존 결과를 검증합니다. 다른 관리자의 동시 쓰기는 한계로 남습니다. 요청 형식은 [GitHub update API](https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection)를 따릅니다.

부재 확인과 승인이 끝난 신규 정책에만 다음 필수 기본 필드를 사용합니다.

```bash
gh api -X PUT "repos/<owner>/<repo>/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

이미 정책이 있는 branch에서는 같은 호출이 그 정책의 `required_status_checks`, `required_pull_request_reviews`, `restrictions`, `enforce_admins` 값을 그대로 body에 실어 보내고 `allow_force_pushes`나 `allow_deletions`만 바꿉니다. `develop`도 `branches/develop/protection`에 같은 방식으로 처리합니다.

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
sh install.sh --target antigravity --scope project --dry-run
```

위 명령은 프로필 없이 스킬 설치 계획을 검증합니다. 설치 후 `jig-setup`을 실행하면 프로필을 선택하고 `develop` 브랜치와 branch protection을 수렴합니다. 설치 중 GitHub 연동까지 하려면 선택적으로 다음처럼 프로필을 전달할 수 있습니다.

```bash
sh install.sh --target antigravity --scope project --github-profile your-account
```

## 로컬 pre-push 가드

서버측 branch protection과 별개로, `github-sync`가 `.git/hooks/pre-push`에 로컬 가드를 설치합니다. 추적되는 원본은 `github-sync/assets/pre-push`로 배포되고 `github-sync/scripts/manage-pre-push.sh`가 결정적으로 설치·갱신합니다. clone마다 로컬에만 존재하므로 새 clone에서는 `github-sync`를 다시 실행해야 합니다.

- `main`/`develop` 대상 force push(non-fast-forward) 차단
- `main`/`develop` 원격 삭제 차단
- `develop:main` fast-forward(릴리즈) 이외의 `main` 직접 push 차단

`--no-verify`로 우회할 수 있는 것이 git hook의 한계입니다. jig 스킬은 우회를 금지하고, 두 번째 겹이 이를 강제합니다 — push 명령을 실행 전에 검사해 `--no-verify`를 포함한 위반 명령을 거부하는 `PreToolUse` hook입니다. Claude Code에서는 이 hook이 `jig` 플러그인 안에 들어 있습니다. Codex는 플러그인 자체의 hook을 실행하지 않으므로 Codex와 Antigravity에서는 `github-sync`가 네이티브로 설치합니다 — 배포된 `github-sync/assets/guard-push.sh`의 clone-local 복사본(`<git common dir>/jig/guard-push.sh`)을 실행하는 항목 하나를 `.codex/hooks.json` 또는 `.agents/hooks.json`에 넣으며, `github-sync/scripts/manage-native-hooks.sh`가 자기 항목만 추가·갱신·제거하고 사용자 항목은 보존합니다. clone-local 복사본 덕분에 jig가 플러그인으로 왔든 스킬 파일로 왔든 같은 항목이 동작합니다. Codex는 사용자가 `/hooks`에서 한 번 검토한 뒤에만 프로젝트 hook을 실행하며 sync 보고서가 이를 알립니다. 저장소가 보호를 걸 수 있으면 서버측 branch protection이 최종 방어선이고, 걸 수 없으면 이 가드들이 유일한 방어선입니다. 두 겹 모두 진단은 `jig-doctor`, 설치·갱신은 `github-sync`가 담당합니다.

프로젝트에서 `github-sync`나 jig를 제거하기 전에는 스킬의 guard cleanup을 실행합니다. 네이티브 hook manager는 자기 항목만 제거하고 다른 항목이 없던 파일만 삭제합니다. pre-push manager는 jig marker가 있는 hook만 제거합니다. 기존 사용자 hook 교체를 명시적으로 허용했던 경우 uninstall이 `.jig-user-backup`을 복원합니다. plugin 또는 global scope 제거는 clone별 `.git` 디렉터리를 열거할 수 없으므로 영향받은 checkout마다 한 번씩 정리해야 합니다.
