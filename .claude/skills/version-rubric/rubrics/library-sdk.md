# 라이브러리·SDK 버전 정책

> 기준: SemVer 라이브러리·SDK형, `<날짜>` 채택

## 공개 인터페이스

- export된 함수, class, type, constant, module path
- signature, generic constraint, 반환값, 오류
- protocol·serialization 형식과 기본값
- extension·plugin hook
- 지원 언어·runtime·compiler 버전
- peer dependency와 소비자에게 노출되는 transitive type

비공개 symbol과 빌드·테스트 구현은 공개 산출물이나 소비자 환경을 바꾸지 않는 한 내부 구현입니다.

## 판정 순서

1. 공개 API와 지원 환경을 유지하며 버그·성능·내부 구현만 수정했는가? → `patch`
2. 기존 consumer code가 그대로 compile·run되면서 새 API·기능만 추가됐는가? → `minor`
3. 기존 consumer code·설정·runtime 또는 직렬화 데이터를 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 API와 의미를 유지하는 수정 | 구현 오류 수정, 성능 개선, 내부 dependency 교체 |
| `minor` | 하위 호환 API 확장 | 새 함수·type 추가, optional parameter를 호환 방식으로 추가 |
| `major` | source·binary·behavior compatibility를 깨는 변경 | export 제거, signature 변경, 기본값 의미 변경, runtime 지원 제거 |

## 강경 규칙

> compile은 성공하지만 같은 호출의 반환 의미·예외·부작용이 달라지면 `major`다.

> type system 특성상 union·enum case 추가가 기존 consumer의 exhaustive check를 깨면 `major`다.

## 릴리즈 전 검증

- 공개 API 또는 ABI diff를 확인한다.
- 최소·최대 지원 runtime과 compiler에서 consumer fixture를 실행한다.
- 직렬화·역직렬화와 이전 데이터 호환성을 시험한다.

## 버전 형식

- package registry 버전과 git tag의 SemVer를 일치시킨다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
