# GitHub Sync

<!-- jig:skill-source-digest 45030d5178a5ce8940bae93441acdb4094bbc8eb -->

[English](../../en/skills/github-sync.md) · [스킬 index](index.md) · [GitHub 저장소 설정](../github-repository-settings.md)

## 개요

`github-sync`는 저장소를 jig의 CLI release 모델에 수렴합니다. `main`·`develop`, 선택적 server-side protection, local `pre-push` guard를 관리합니다. 멱등적이며 release, tag, PR template, label, Release Drafter automation은 다루지 않습니다.

## 사용 시점

`jig-setup` 중, `jig-update` 후, `develop`이 없을 때, protection이나 local guard가 drift됐을 때, 새 clone에 protection 선택이 기록되지 않았을 때 사용합니다. 발행은 `github-release`의 역할이며 sync는 release를 만들지 않습니다.

## 실행 방법과 전제 조건

- Claude Code: `/jig:github-sync`
- Codex·Antigravity: `jig-github-sync`
- Git 저장소가 필요합니다. GitHub 작업에는 `gh`, 저장소 권한, `JIG_GITHUB_PROFILE` 또는 local `jig.githubProfile`이 필요합니다.

## 작업 흐름

```mermaid
flowchart TD
    Inspect[worktree, remote, gh access 점검] --> Main{main 존재?}
    Main -- No --> Stop[선행 조건 누락 보고]
    Main -- Yes --> Develop{develop 존재?}
    Develop -- No --> Create[main에서 develop 생성 후 push]
    Develop -- Yes --> Probe
    Create --> Probe[admin·visibility·protection API probe]
    Probe --> Available{protection 사용·변경 가능?}
    Available -- No --> Guard[관리형 pre-push installer 실행]
    Available -- Yes --> Choice{기록된 선택?}
    Choice -- enabled --> Apply[정책 수렴]
    Choice -- skipped --> Guard
    Choice -- none --> Ask[한 번 확인]
    Ask -- Yes --> Apply
    Ask -- No --> Record[local skipped 기록]
    Apply --> Guard
    Record --> Guard
    Guard --> Legacy[legacy release 파일 보고]
```

protection은 두 branch의 force push와 삭제를 막지만 PR review와 status check를 요구하지 않습니다. protection을 제공하지 않는 plan의 private 저장소가 `403`을 반환하는 것은 defect가 아니라 정보입니다.

## 읽기·변경 범위

Git branch·remote, GitHub permission·protection, `jig.githubProfile`, `jig.githubHost`, `jig.branchProtection`을 읽습니다. `develop`을 생성·push하고, 확인 후 protection을 적용하고, local 선택을 기록하고, 배포된 `assets/pre-push` 원본과 `scripts/manage-pre-push.sh` helper로 `.git/hooks/pre-push`를 관리할 수 있습니다.

local guard는 `main`·`develop` 삭제와 non-fast-forward push를 막고 `main`은 `develop:main`으로만 갱신하게 합니다. local 방어일 뿐이며 server-side protection이 최종 방어선입니다.

helper는 원자적으로 설치하고 jig 소유 설치본의 drift를 복구하며 `core.hooksPath`가 설정돼 있으면 설치를 거부합니다. marker가 없는 사용자 hook은 명시적 확인 없이 교체하지 않습니다. 교체가 승인되면 `.git/hooks/pre-push.jig-user-backup`으로 보존합니다.

## 판단 지점과 안전 규칙

- checkout이 `enabled`나 `skipped`를 기록하지 않았고 protection이 가능하면 한 번 묻습니다.
- marker가 없는 사용자 `pre-push` hook은 명시적 확인과 `.jig-user-backup` 없이 덮어쓰지 않습니다.
- force push, branch 삭제, tag·release 생성, `core.hooksPath` 설정, default branch 이름 변경, legacy 파일 무단 삭제를 하지 않습니다.
- protection이 불가하거나 건너뛰면 local guard가 이 머신의 유일한 방어선임을 보고합니다.

## 제거 정리

현재 프로젝트에서 스킬이나 플러그인을 제거하기 전에 helper의 `uninstall` mode를 실행합니다. jig 소유 marker가 있는 hook만 제거하며 승인 후 보존했던 사용자 hook이 있으면 복원합니다. user/global 설치 제거로는 모든 clone을 발견할 수 없으므로 각 프로젝트 checkout에서 명시적으로 정리해야 합니다.

## 결과물

branch 생성·현재 상태, protection의 applied·skipped·unavailable·not permitted 상태, local guard, legacy 파일, 실행하지 못한 명령과 다음 조치를 보고합니다.

## 관련 스킬

- [`jig-setup`](jig-setup.md): sync 전 GitHub 프로필 선택
- [`jig-update`](jig-update.md): payload 갱신 후 저장소 수렴 위임
- [`jig-doctor`](jig-doctor.md): protection·guard drift read-only 진단
- [`github-release`](github-release.md): 수렴된 branch 모델 사용

## 원본

- [`skills/github-sync/SKILL.md`](../../../skills/github-sync/SKILL.md)
- [GitHub 저장소 설정](../github-repository-settings.md)
