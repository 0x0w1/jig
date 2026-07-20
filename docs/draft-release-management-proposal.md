# GitHub Releases 운영 방식 변경 제안

> 상태: 검토용 초안  
> 작성일: 2026-07-20

## 결론

GitHub Releases는 PR이 아니라 Git 태그를 기준으로 특정 배포 지점을 기록한다. PR은 변경 검토와 릴리즈 노트 생성을 위한 입력으로 활용할 수 있지만, 릴리즈 추적의 필수 조건은 아니다.

SPAI에는 **개발 변경은 PR로 관리하고, 릴리즈 자체는 태그로 관리하는 방식**을 권장한다.

```text
작업 브랜치 → main PR → 병합 → Release Draft 누적 → vX.Y.Z 릴리즈 실행 → 태그·GitHub Release 생성
```

현재의 `develop → release/* → main` 승격 구조를 유지해야 할 별도의 승인 또는 배포 요건이 없다면, 장기 브랜치를 `main`으로 단순화하는 편이 운영 비용과 실패 지점을 줄일 수 있다.

## 운영 방식 비교

| 방식 | 변경 기록 원천 | 릴리즈 승인 방식 | 장점 | 단점 | SPAI 적합도 |
|---|---|---|---|---|---:|
| 현재 방식 | `develop` 대상 PR 본문·라벨 | `release/* → main` PR | `main`에 공개 버전만 존재하고 릴리즈 승인이 명확함 | 작업 PR과 릴리즈 PR이 중복되고 `develop` PR 연결을 복원하는 로직이 복잡함 | 보통 |
| GitHub Flow + Release Drafter | `main` 대상 PR 제목·라벨 | 버전 입력 후 태그 게시 | 구조가 단순하고 GitHub 기능과 자연스럽게 연결됨 | `main`에 아직 릴리즈하지 않은 변경도 존재함 | **매우 높음** |
| release-please | Conventional Commit | 봇이 만든 Release PR 병합 | 버전, `CHANGELOG`, 태그가 일관되고 릴리즈 검토가 가능함 | 커밋 규칙과 봇 관리가 필요하고 Release PR은 여전히 존재함 | 높음 |
| semantic-release | Conventional Commit | CI 자동 게시 | 릴리즈 작업을 거의 완전히 자동화할 수 있음 | 자동화 통제가 강하고 커밋 규칙을 엄격하게 지켜야 함 | 낮음 |
| Changesets | 저장소 내 변경 설명 파일 | Version PR 병합 | 기록이 Git에 남고 여러 패키지 버전 관리에 강함 | 변경 설명 파일과 Version PR 관리가 추가됨 | 낮음 |
| 수동 태그·수동 노트 | 태그 비교와 사람이 작성한 요약 | 관리자 직접 게시 | 자유도가 높고 사용자 중심으로 노트를 작성할 수 있음 | 누락 가능성이 높고 반복 작업이 많음 | 보통 |

SPAI는 단일 설치 스크립트와 스킬 배포물이 중심이므로, 모노레포에 적합한 Changesets나 완전 자동화 중심의 semantic-release보다 **GitHub Flow + Release Drafter**가 가장 균형이 좋다.

## 구체적인 변경 제안

| 영역 | 현재 | 제안 | 이유 |
|---|---|---|---|
| 기본 브랜치 | `main`, `develop` | `main`만 장기 유지 | 브랜치 간 동기화와 승격 작업 제거 |
| 작업 브랜치 | `feature/*`, `fix/*`, `chore/*` | 그대로 유지 | 변경 단위와 목적을 명확하게 유지 |
| 작업 PR 대상 | `develop` | `main` | Release Drafter가 작업 PR을 직접 인식 |
| 릴리즈 브랜치 | `release/vX.Y.Z` | 제거 | 태그가 릴리즈 스냅샷 역할을 담당 |
| 릴리즈 PR | `release/* → main` | 제거 | 릴리즈 승인을 workflow 실행 권한으로 대체 |
| 릴리즈 트리거 | Release PR 병합 | `workflow_dispatch`에서 `vX.Y.Z` 입력 | 릴리즈 시점을 명시적으로 통제 |
| 릴리즈 노트 | `develop` PR을 후처리로 다시 조회 | `main`에 병합된 PR을 Release Drafter가 직접 취합 | 커스텀 후처리와 PR 연결 실패 감소 |
| 버전 결정 | Release PR의 `patch`, `minor`, `major` 라벨 | 사용자가 정확한 `vX.Y.Z` 입력 | 실제 버전과 라벨 추론 결과의 불일치 방지 |
| 변경 분류 | `enhancement`, `fix`, `chore` | 그대로 유지 | 릴리즈 노트 카테고리로 활용 |
| 릴리즈 제외 | 전용 라벨 없음 | `skip-release-note` 추가 고려 | CI, 내부 리팩터링 등 사용자에게 불필요한 변경 제외 |
| 변경 추적 | PR 연결 정보에 상당 부분 의존 | 태그 비교와 PR 링크 병행 | PR 연결이 누락되어도 태그 사이 커밋 추적 가능 |
| `CHANGELOG.md` | 없음 | 당장은 추가하지 않음 | GitHub Releases와 중복되는 기록 관리 방지 |

## 스킬과 설정 변경 방향

| 파일 또는 스킬 | 변경 방향 |
|---|---|
| `develop-task-flow` | `main`에서 작업 브랜치를 만들고 PR도 `main`으로 보내도록 변경 |
| `github-release` | Release branch와 Release PR 생성 단계를 제거하고 `main`의 특정 커밋을 `vX.Y.Z`로 게시하도록 변경 |
| `github-sync` | `develop` 생성·보호 규칙을 제거하고 `main` 보호와 Release Drafter 설정만 관리 |
| `AGENTS.md` | `main` 기반 GitHub Flow와 태그 기반 릴리즈 모델로 변경 |
| Release Drafter workflow | `main` PR 병합 시 draft를 갱신하고 수동 실행 시 지정 버전으로 게시 |
| 릴리즈 후처리 스크립트 | `base.ref === develop` 복원 로직을 제거하고 필요하면 `main` PR의 `Summary`만 처리 |

## 권장 운영 정책

- `main`은 항상 테스트를 통과하고 릴리즈 가능한 상태로 유지한다.
- 모든 일반 변경은 작업 브랜치에서 PR을 통해 `main`에 병합한다.
- 작업 PR에는 `enhancement`, `fix`, `chore` 중 하나를 적용한다.
- 릴리즈가 필요할 때만 정확한 `vX.Y.Z`를 입력해 workflow를 실행한다.
- 릴리즈 workflow는 테스트, 버전 중복 확인, 태그 생성, Release Drafter 게시를 수행한다.
- 릴리즈 기록의 기준은 개별 PR이 아니라 `이전 태그..현재 태그` 범위로 삼는다.
- 상세한 구현 설명은 PR의 `Summary`와 `Details`에 두고, 사용자가 알아야 하는 핵심 내용만 릴리즈 노트에 포함한다.
- 사용자에게 노출할 필요가 없는 변경은 `skip-release-note`로 제외하는 방안을 검토한다.

## 현재 구조를 유지해야 하는 경우

다음 요건이 있다면 현재 `develop → release/* → main` 구조를 유지하는 편이 적합하다.

- `main`에는 이미 외부에 공개된 코드만 존재해야 한다.
- 개발 완료와 배포 승인 사이에 명확한 조직적 승인 단계가 필요하다.
- 여러 변경을 통합 환경에서 장기간 검증한 뒤 한 번에 승격해야 한다.
- 릴리즈 PR 자체가 감사 또는 변경 승인 기록으로 요구된다.

이 경우 Release PR은 유지하되 릴리즈 노트의 원천을 변경 가능한 PR 본문 대신 저장소 안의 변경 설명 파일로 옮기는 방안을 고려한다. 예를 들어 작업 PR마다 `.changes/*.md`를 추가하고 Release PR에서 이를 취합하면, PR 연결 정보가 누락되어도 릴리즈 설명을 Git 기록에서 복원할 수 있다.

## 참고 자료

- [GitHub: About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
- [GitHub: Automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)
- [GitHub: Comparing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/comparing-releases)
- [Release Drafter](https://github.com/release-drafter/release-drafter)
- [release-please](https://github.com/googleapis/release-please)
- [semantic-release](https://semantic-release.gitbook.io/semantic-release)
- [Changesets](https://github.com/changesets/changesets)
- [Kubernetes: Adding Release Notes](https://www.kubernetes.dev/docs/guide/release-notes/)
