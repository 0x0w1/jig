# 모바일 앱 버전 정책

> 기준: SemVer 모바일 앱형, `<날짜>` 채택

## 공개 인터페이스

- 사용자가 완료할 수 있는 주요 작업 흐름과 기본 동작
- deep link, universal link, app link
- 로컬 데이터·백업·동기화 형식
- push notification payload와 처리 규칙
- 서버 API와의 지원 버전 범위
- 지원 OS, device capability, extension·widget 계약
- 다른 앱에 공개한 URL scheme와 SDK

내부 UI framework나 빌드 시스템은 위 계약을 바꾸지 않는 한 내부 구현입니다.

## 판정 순서

1. 기존 작업 흐름·데이터·연동을 유지하며 앱 결함만 수정했는가? → `patch`
2. 기존 설치본과 사용법을 유지하면서 선택 기능·화면·플랫폼 지원만 추가했는가? → `minor`
3. 기존 사용자가 데이터·설정·OS·연동 또는 사용 방식을 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 앱 계약을 유지하는 수정 | crash 수정, battery 사용량 개선, 동기화 결함 수정 |
| `minor` | 기존 사용법과 공존하는 기능 추가 | opt-in 기능, 새 widget, 새 deep link 추가 |
| `major` | 기존 설치본·데이터·연동과 비호환인 변경 | 로컬 데이터 수동 변환, URL scheme 제거, 최소 OS 상향으로 기존 기기 제외 |

## 강경 규칙

> build number와 SemVer는 별개다. 심사 재제출이나 동일 기능 재빌드만으로 SemVer 등급을 올리지 않는다.

> 서버가 이전 앱 버전 지원을 중단하거나 강제 업데이트가 필요해지면 앱과 서버의 호환 계약을 `major`로 판정한다.

## 릴리즈 전 검증

- 이전 공개 버전에서 데이터 upgrade와 로그인 유지 여부를 시험한다.
- 지원 중인 서버·앱 버전 조합을 contract test로 확인한다.
- deep link, notification, background task를 실제 배포 형태로 확인한다.

## 버전 형식

- 사용자용 SemVer와 스토어용 build number를 분리한다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
