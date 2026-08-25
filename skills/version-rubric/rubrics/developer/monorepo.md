# 모노레포 버전 정책

> 기준: SemVer 모노레포형, `<날짜>` 채택

모노레포라는 디렉토리 구조 자체는 버전 전략을 결정하지 않습니다. 공개되는 제품·패키지의 소비 방식에 따라 고정 버전, 독립 버전, 혼합 버전 중 하나를 명시적으로 선택합니다.

## 공개 인터페이스

- 각 package·service·app가 유형별 문서에서 정의한 공개 계약
- workspace package 사이의 dependency와 지원 버전 범위
- 공유 schema, protocol, generated client
- 통합 배포가 보장하는 cross-package compatibility
- root command, build·release entrypoint

## 버전 전략

### 고정 버전

모든 산출물을 하나의 제품으로 배포하고 항상 같은 버전을 부여합니다.

- package별로 등급을 판정한 뒤 가장 높은 등급을 전체 버전에 적용합니다.
- 변경되지 않은 package도 같은 버전으로 발행할 수 있습니다.
- 서버·클라이언트가 하나의 호환성 단위일 때 적합합니다.

### 독립 버전

각 package가 별도 소비자와 릴리즈 주기를 가집니다.

- 영향을 받은 package만 각자 SemVer를 올립니다.
- dependency range 변경이 소비 package의 공개 계약에 미치는 영향도 따로 판정합니다.
- root에는 제품 버전을 두지 않거나 release manifest만 둡니다.

### 혼합 버전

제품군은 고정 버전으로 묶고 독립 도구·라이브러리는 별도 버전을 사용합니다.

- version group을 문서에 열거합니다.
- group 안에서는 최고 등급을 사용하고 group 사이는 독립 판정합니다.
- package를 group 사이로 이동하면 소비자 설치·호출 방식의 호환성을 판정합니다.

## 판정 순서

1. 영향받은 version unit의 공개 계약을 유지하며 결함·내부 구현만 수정했는가? → `patch`
2. 기존 소비자와 package 조합을 유지하면서 하위 호환 기능만 추가했는가? → `minor`
3. 기존 소비자나 workspace package가 코드·설정·dependency·배포 순서를 바꿔야 하는가? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | version unit의 공개 계약을 유지하는 수정 | 내부 package refactor, 호환 가능한 버그 수정 |
| `minor` | 기존 package 조합과 공존하는 기능 추가 | 새 package, 하위 호환 API 추가, optional integration 추가 |
| `major` | 소비자 또는 package 사이 계약을 깨는 변경 | package 제거, export 변경, dependency range 비호환, 필수 배포 순서 변경 |

## 강경 규칙

> 변경량이나 영향받은 package 수로 등급을 정하지 않는다. package가 많아도 모두 호환 수정이면 `patch`다.

> generated client와 schema가 함께 바뀌어 저장소 안에서는 성공하더라도 외부 소비자가 깨지면 `major`다.

> 여러 version unit에 서로 다른 판정이 나오면 고정·group 버전은 최고 등급을 사용하고, 독립 버전은 각각의 등급을 사용한다.

## 릴리즈 전 검증

- 변경된 package와 역의존 package의 테스트를 실행한다.
- 지원되는 이전·새 package 버전 조합을 contract test로 확인한다.
- 실제 발행 대상, dependency range, changelog와 tag가 선택한 전략과 일치하는지 확인한다.

## 버전 형식

- 고정 버전은 `vX.Y.Z`, 독립 버전은 `<package>@X.Y.Z`처럼 충돌 없는 tag 규칙을 정한다.
- version group과 package별 현재 버전의 source of truth를 하나로 고정한다.
- `0.x`에서 `major` 판정은 해당 version unit의 minor 자리를 올리되 판정 결과는 `major`로 기록한다.
