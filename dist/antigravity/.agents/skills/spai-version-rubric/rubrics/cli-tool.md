# CLI 도구 버전 정책

> 기준: SemVer CLI 도구형, `<날짜>` 채택

## 공개 인터페이스

- command, subcommand, option, positional argument
- 기본값, exit code, signal 처리
- stdout·stderr 중 기계가 소비하는 출력과 `--json` schema
- config file, environment variable, credential lookup
- shell completion과 automation contract
- 지원 OS, shell, runtime

사람에게만 보이는 진행 문구나 내부 module은 자동화 계약을 바꾸지 않는 한 내부 구현입니다. 다만 human-readable 출력이라도 문서에서 parsing 대상으로 보장했다면 공개 인터페이스입니다.

## 판정 순서

1. 기존 command·option·출력·설정을 유지하며 결함만 수정했는가? → `patch`
2. 기존 script가 그대로 동작하면서 새 command·option·출력 mode만 추가됐는가? → `minor`
3. 기존 script나 사용자가 호출·파싱·설정 방식을 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 기존 CLI 계약을 유지하는 수정 | 잘못된 exit code 복구, 오류 처리 개선, human-readable 문구 교정 |
| `minor` | 기존 호출과 공존하는 기능 추가 | 새 subcommand, opt-in flag, 새 `--json` field 추가 |
| `major` | 기존 명령·자동화와 비호환인 변경 | option 제거·rename, 기본값 변경, JSON field 변경, 지원 shell 제거 |

## 강경 규칙

> deprecated option이 새 이름을 안내하며 실패하더라도 기존 자동화가 중단되면 `major`다.

## 릴리즈 전 검증

- 이전 버전의 대표 command fixture와 exit code를 비교한다.
- `--json` 등 기계 판독 출력의 schema diff를 확인한다.
- config와 environment variable의 precedence를 시험한다.

## 버전 형식

- package·binary·`--version` 출력과 git tag의 SemVer를 일치시킨다.
- `0.x`에서 `major` 판정은 `v0.Y.Z` → `v0.(Y+1).0`으로 표현하되 판정 결과는 `major`로 기록한다.
