# 백그라운드 워커 버전 정책

> 기준: SemVer 백그라운드 워커형, `<날짜>` 채택

## 공개 인터페이스

- queue·stream·event message schema와 의미
- topic, routing key, partition key
- retry, timeout, dead-letter, idempotency 정책
- 처리 순서와 delivery guarantee
- database·외부 시스템에 만드는 side effect
- producer·consumer와의 지원 버전 범위
- 운영자가 사용하는 metric, alert, replay 절차

내부 concurrency 모델과 worker framework는 처리 계약을 바꾸지 않는 한 내부 구현입니다.

## 판정 순서

1. 기존 메시지·처리 결과·운영 계약을 유지하며 결함만 수정했는가? → `patch`
2. 기존 producer와 consumer를 유지하면서 선택적 메시지·handler·metric만 추가했는가? → `minor`
3. 기존 producer·consumer·데이터·운영 절차를 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 처리 계약을 유지하는 수정 | 중복 처리 버그 수정, 처리량 개선, retry 구현 복구 |
| `minor` | 기존 메시지 흐름과 공존하는 확장 | 새 event type, optional field, opt-in handler 추가 |
| `major` | 메시지·순서·부작용과 비호환인 변경 | 필수 field 추가, topic 이동, idempotency key 변경, delivery 의미 변경 |

## 강경 규칙

> 같은 메시지가 성공 처리되지만 데이터 side effect나 전달 보장이 달라지면 `major`다.

> backlog replay가 이전과 다른 결과를 만들거나 수동 데이터 정리가 필요하면 `major`다.

## 릴리즈 전 검증

- 이전 producer와 새 consumer, 새 producer와 지원 중인 consumer 조합을 시험한다.
- 중복·지연·역순·실패 메시지의 contract test를 수행한다.
- backlog replay, dead-letter 복구, rollback 영향을 확인한다.

## 버전 형식

- 배포 revision과 공개 계약의 SemVer를 분리한다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
