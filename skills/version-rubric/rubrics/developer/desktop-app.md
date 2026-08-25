# 데스크톱 앱 버전 정책

> 기준: SemVer 데스크톱 앱형, `<날짜>` 채택

## 공개 인터페이스

- 사용자가 완료할 수 있는 작업 흐름과 기본 동작
- 문서·프로젝트·설정 파일 형식
- 데이터 저장 위치와 migration
- protocol URL, file association, shell integration
- plugin·extension API
- 자동 업데이트 channel과 호환성
- 지원 OS, CPU architecture, system requirement

내부 UI toolkit이나 packaging 도구는 설치·데이터·연동 계약을 바꾸지 않는 한 내부 구현입니다.

## 판정 순서

1. 기존 파일·설정·연동·작업 흐름을 유지하며 결함만 수정했는가? → `patch`
2. 기존 설치와 파일을 그대로 지원하면서 선택 기능·형식·연동만 추가했는가? → `minor`
3. 기존 사용자가 파일·설정·플러그인·OS 또는 설치 방식을 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 데스크톱 계약을 유지하는 수정 | crash 수정, 렌더링 결함 수정, updater 안정화 |
| `minor` | 기존 환경과 공존하는 기능 추가 | 새 export 형식, opt-in integration, 새 OS 지원 |
| `major` | 기존 설치·데이터·확장과 비호환인 변경 | 파일 형식 비호환, plugin API 제거, 지원 OS·architecture 제거 |

## 강경 규칙

> 앱이 기존 파일을 열 수 있지만 저장 시 이전 버전에서 다시 열 수 없는 형식으로 조용히 바꾸면 `major`다.

> 코드 서명·권한·설치 위치 변경으로 사용자의 수동 조치가 필요하면 `major`다.

## 릴리즈 전 검증

- 이전 버전의 파일·설정·플러그인으로 upgrade test를 수행한다.
- 자동 업데이트와 rollback 경로를 지원 OS별로 확인한다.
- file association과 protocol handler를 설치본에서 확인한다.

## 버전 형식

- auto-update channel과 SemVer prerelease 식별자를 일관되게 매핑한다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
