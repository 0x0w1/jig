# 버전 정책

> 기준: 직접 작성 (설치본이 치르는 비용 축), 2026-08-19

jig는 다른 저장소에 설치되는 도구다. 릴리즈 노트의 주 소비자가 사람이 아니라 `jig-update` 스킬이므로, 에이전트가 무인으로 처리할 수 있는 변경과 사람의 판단이 필요한 변경을 같은 등급으로 묶지 않는다.

이 파일이 jig 릴리즈 판정의 규범 원본이다. `github-release`가 릴리즈할 때 읽는다. 사람이 읽는 해설과 적용 예는 [docs/ko/versioning.md](../docs/ko/versioning.md)에 있다.

## 판정 순서

1. 설치본이 아무것도 하지 않아도 되거나, 업데이트 재실행만으로 수렴하는가? → `patch`
2. 깨지긴 하지만 (a) `jig-update`가 무인으로 복구하거나 (b) 실패 지점에서 대체 수단을 즉시 제시하는가? → `minor`
3. 사람의 판단이 필요하거나, 실패 없이 조용히 동작만 바뀌는가? → `major`

## 등급 정의

| bump | 정의 |
|---|---|
| `patch` | 공개 인터페이스가 그대로다. 내부 구현, 문서, 스킬 본문 문구, `dist` 재생성 |
| `minor` | 새 기능, 또는 유도된 파괴(guided break). 실패가 시끄럽고 자기 수정 방법을 함께 알려준다 |
| `major` | 사람의 결정이 필요하거나, 동작이 조용히 바뀐다. 브랜치 모델·보호 정책 변경, 사용자 파일·라벨 삭제, 같은 명령이 에러 없이 다른 결과를 내는 변경 |

핵심 완화는 고칠 수 있는 파괴를 `minor`로 본다는 점이다. 그 대가로 아래 강경 규칙이 붙는다.

## 강경 규칙

> 조용한 동작 변경은 무조건 `major`다. 크기와 무관하다.

> 릴리즈 노트에 `migration-manual` 블록이 하나라도 있으면 `major`다. `migration-auto` 블록만 있으면 최소 `minor`다. 블록은 줄 전체가 marker일 때만 센다(`^<!-- jig:start migration-manual -->$`).

실패가 시끄러우면 사용자 비용은 오류 메시지 한 줄이고, 조용하면 디버깅 세션이다. 이 가드가 있어야 나머지를 느슨하게 풀어도 정직하다.

## 공개 인터페이스

여기가 깨지면 최소 `minor`다.

1. installer와 설치 후 GitHub 프로필 계약: `--target`, `--scope`, 선택 옵션 `--github-profile`/`--github-account`, `JIG_GITHUB_PROFILE`, `jig.githubProfile`
2. 스킬 호출 이름: `/jig:<skill>`, `jig-<skill>`
3. 플러그인·마켓플레이스 이름: `jig@jig`, `0x0w1/jig`
4. managed block marker 문자열: `<!-- jig:start ... -->`, `<!-- jig:end ... -->`
5. 저장소 모델: 브랜치 이름, 병합 흐름, 보호 정책
6. 버전 판정 기준 계약: `.jig/versioning.md` 경로, `JIG_VERSION_RUBRIC`, `jig.versionRubric`, 섹션 제목 `## 판정 순서`·`## 등급 정의`

내부 — 깨져도 `patch`: `dist/` 레이아웃, `scripts/*`, 스킬 본문 내용, 버전 스탬프의 `version` 외 필드, 로그 문구, `README`·`docs` 구조

## 릴리즈 전 검증

- `sh scripts/validate-dist.sh`

## 버전 형식

- 태그는 `^v[0-9]+\.[0-9]+\.[0-9]+$`를 만족해야 한다.
- major 버전이 `0`인 동안 `major` 판정은 minor 자리를 올린다: `v0.Y.Z` → `v0.(Y+1).0`. 판정 자체는 1.0 이후와 동일하게 하고 릴리즈 보고에 판정 결과를 남긴다.
- 릴리즈 노트 `### Summary`는 한국어, 기술 용어는 백틱.
