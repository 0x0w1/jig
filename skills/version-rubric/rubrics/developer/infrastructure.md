# 인프라 프로젝트 버전 정책

> 기준: SemVer 인프라형, `<날짜>` 채택

## 공개 인터페이스

- module·chart·template의 input, output, variable, default
- 생성되는 리소스의 이름과 외부 참조점
- state, import, upgrade 계약
- network, identity, secret, storage 경계
- 지원 provider·platform·region·tool version
- availability, backup, retention, recovery 보장
- 소비 프로젝트가 따라야 하는 배포·운영 절차

리소스 내부 구성은 비용·가용성·보안·운영 계약에 영향을 주지 않는 한 구현 세부사항입니다.

## 판정 순서

1. 기존 input·state·운영 계약을 유지하며 결함·비용·성능만 수정했는가? → `patch`
2. 기존 적용 결과를 유지하면서 선택적 resource·variable·output만 추가했는가? → `minor`
3. 기존 소비자가 state·설정·권한·운영 절차를 바꾸거나 중단을 감수해야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 인프라 계약을 유지하는 수정 | 잘못된 policy 수정, tag 누락 복구, 무중단 성능 개선 |
| `minor` | 기존 구성과 공존하는 opt-in 확장 | optional resource, variable, output 추가 |
| `major` | state·리소스·운영과 비호환인 변경 | variable 제거, resource address 변경, 수동 import, downtime 필요, 지원 provider 제거 |

## 강경 규칙

> plan이 성공하더라도 기존 리소스를 예상 밖으로 교체·삭제하거나 보안·가용성 의미를 바꾸면 `major`다.

> 비용 변화만으로 등급을 정하지 않지만, 기존 계약을 벗어난 필수 비용이나 운영 책임이 생기면 `major`다.

## 릴리즈 전 검증

- 이전 버전으로 만든 state에 새 버전의 plan을 실행해 replacement와 deletion을 확인한다.
- 최소·최대 지원 provider와 tool version을 시험한다.
- backup, migration, rollback 및 장애 복구 절차를 검증한다.

## 버전 형식

- module·chart 등 소비 가능한 산출물의 버전과 배포 환경 revision을 분리한다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
