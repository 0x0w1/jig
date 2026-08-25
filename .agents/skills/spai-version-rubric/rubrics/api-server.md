# API 서버 버전 정책

> 기준: SemVer API 서버형, `<날짜>` 채택

## 공개 인터페이스

- endpoint의 method와 path
- request·response·error schema와 의미
- HTTP status code, header, pagination, 정렬 기본값
- 인증·인가 방식과 scope
- webhook, event, rate limit 계약
- 공개된 API 버전과 지원 기간

내부 저장소, 프레임워크, 배포 topology는 외부 계약에 영향을 주지 않는 한 공개 인터페이스가 아닙니다.

응답 필드 추가를 호환 변경으로 볼 수 있는지는 "모르는 필드는 무시한다"는 계약이 클라이언트와 있는지에 달렸습니다. 그 계약이 없으면 응답 스키마 전체가 공개 인터페이스이고, 필드 추가도 `major`입니다.

## 판정 순서

1. 공개 API 계약을 유지하며 잘못된 동작·성능·안정성만 수정했는가? → `patch`
2. 기존 요청과 응답을 유지하면서 선택적 endpoint·필드·기능만 추가했는가? → `minor`
3. 기존 호출자가 요청·파싱·인증·오류 처리를 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 API 계약과 의미를 유지하는 수정 | 명세대로 status code 수정, N+1 제거, timeout 안정화 |
| `minor` | 기존 호출에 영향을 주지 않는 API 확장 | 새 endpoint, optional request field, additive response field |
| `major` | 기존 호출·해석·인증과 호환되지 않는 변경 | endpoint 제거, 필수 필드 추가, 필드 의미 변경, 인증 방식 교체 |

## 강경 규칙

> 기존 요청이 성공하면서 결과 의미·권한·부작용이 달라지는 변경은 `major`다.

## 릴리즈 전 검증

- OpenAPI 또는 schema diff로 breaking change를 확인한다.
- 지원 중인 클라이언트 버전으로 contract test를 실행한다.
- 데이터 migration과 rollback이 기존 API 응답에 미치는 영향을 확인한다.

## 버전 형식

- 제품 SemVer와 URL의 `/v1` 같은 API 세대 표시는 별도다. API 세대를 유지해도 제품 릴리즈가 `major`일 수 있고, 새 API 세대를 `minor` 릴리즈에 병행 추가할 수도 있다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
