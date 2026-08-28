# 버전 판정 기준

[English](version-rubric.md)

jig가 릴리즈 등급(`patch`/`minor`/`major`)을 어떤 기준으로 가를지는 **프로젝트가 결정합니다.** 그 결정은 저장소 안의 파일 하나에 담기고 `github-release`가 릴리즈할 때 그 파일을 읽습니다.

판정 축은 프로젝트마다 다릅니다. 기본은 사람이 손대야 하는지로 가르고 문서 관리 프로젝트는 산출물 종류로 가릅니다. 같은 임계값을 조절하는 문제가 아니라 축 자체가 다르기 때문에 판정 기준을 스킬에 고정하지 않고 프로젝트로 내보냈습니다.

유형별 초안은 스킬과 함께 배포되는 **기준 카탈로그**에 들어 있습니다. 처음부터 쓸 필요가 없습니다. 어떤 유형인지 모르겠으면 `rubric-scan`이 저장소를 스캔해 후보를 골라 줍니다. 두 가지는 아래 [기준 카탈로그](#기준-카탈로그)에서 설명합니다.

## 파일 위치

```text
.jig/
└── versioning.md
```

- `.jig/`는 **프로젝트가 소유합니다.** installer와 `jig-update`는 이 디렉토리를 쓰지도 지우지도 않고 `jig-doctor`는 이 안의 내용을 드리프트로 보지 않습니다. 직접 고친 내용이 정답입니다.
- 이 파일은 **커밋해야 합니다.** 커밋하지 않으면 clone과 CI에 전달되지 않아 사람마다 다른 기준으로 판정합니다. `jig-doctor`가 미커밋 상태를 경고합니다.
- `.gitignore`에 넣지 마세요.

## 기준 카탈로그

유형별 초안은 `version-rubric` 스킬 payload 안에 함께 설치됩니다. 설치 위치는 CLI마다 다릅니다.

| 환경 | 카탈로그 경로 |
|---|---|
| Claude Code | `${CLAUDE_PLUGIN_ROOT}/skills/version-rubric/rubrics` |
| Codex · Antigravity (project) | `.agents/skills/jig-version-rubric/rubrics` |
| jig 저장소 자체 | [`skills/version-rubric/rubrics`](../skills/version-rubric/rubrics/INDEX.md) |

```text
rubrics/
├── INDEX.md         # 유형 목록과 탐지 신호. 스캔은 이 파일만 읽습니다
├── _template.md     # 카탈로그에 없는 유형을 새로 쓸 때의 골격
├── common.md        # 유형과 무관한 공통 SemVer 원칙
└── <유형>.md         # 유형별 초안 17종. 분류 디렉토리 없이 한 층
```

유형 문서는 평평하게 둡니다. 분류는 `INDEX.md` 표의 `소비자` 열이 하고 한 프로젝트가 여러 성격을 겸하는 일이 흔하기 때문입니다. 디렉토리로 갈라 두면 겸하는 유형이 한쪽으로 밀려나고 성격이 바뀔 때 경로까지 움직입니다.

| 소비자 성격 | 유형 |
|---|---|
| 호출·실행되는 것 | `api-server`, `background-worker`, `data-pipeline` |
| 설치해 쓰는 화면 | `web-client`, `mobile-app`, `desktop-app` |
| 가져다 쓰는 코드 | `library-sdk`, `cli-tool`, `agent-skill-pack` |
| 환경을 바꾸는 것 | `infrastructure`, `config-collection` |
| 여러 패키지를 감싸는 것 | `monorepo` |
| 읽고 보는 것 | `document-archive`, `content-site`, `course-material` |
| 가져다 쓰는 자산·데이터 | `design-assets`, `dataset` |

프로젝트를 만든 사람이 개발자인지 아닌지는 판정과 무관합니다. 문서만 있는 저장소를 개발자가 관리해도 `document-archive`이고 디자이너가 관리하는 저장소가 API를 배포하면 `api-server`입니다.

### 카탈로그와 기본 기준은 축이 다릅니다

카탈로그 17종은 **SemVer 소비자 호환 축**으로 판정합니다. 위의 [기본 기준](#기본-기준-사람-개입-축)은 **사람 개입 축**입니다. 두 축은 같은 변경을 다르게 판정합니다.

| 변경 | 카탈로그 | 기본 기준 |
|---|---|---|
| 기능·endpoint 제거 | `major` | `minor` |
| 세대 교체, 계약 유지 | `patch` | `minor` |
| 조용한 동작 변경 | `major` | `major` |

둘 중 하나만 씁니다. 문항을 섞으면 판정 순서가 어디서 멈추는지가 흐려집니다. 설치본·호출자·독자처럼 **바깥 소비자가 분명한 프로젝트**는 카탈로그가, 소비자가 자기 자신이거나 아직 정해지지 않은 프로젝트는 기본 기준이 맞습니다.

카탈로그 파일은 그대로 `.jig/versioning.md`가 될 수 있게 쓰여 있습니다. 복사한 뒤 `> Basis:` 줄의 날짜와 `## Public Interface` 목록만 프로젝트에 맞게 고칩니다. 카탈로그 자체는 payload라서 `jig-update`가 갱신합니다 — 프로젝트의 결정은 카탈로그가 아니라 기준 파일에 적습니다.

### 유형 스캔

`rubric-scan` 스킬은 저장소를 읽어 유형 후보를 고릅니다. Claude Code는 `/jig:rubric-scan`, Codex와 Antigravity는 `jig-rubric-scan`입니다.

1. 추적 파일 목록, 확장자 분포, 의존성 manifest, 배포 설정, 커밋 이력을 읽습니다.
2. `INDEX.md`의 신호 표와 맞춰 점수를 냅니다 — 강한 신호 2점, 약한 신호 1점, 3점 미만은 후보에서 제외합니다.
3. 후보 최대 3개를 **점수를 만든 실제 경로와 함께** 보고합니다. 근거 경로 없는 추천은 하지 않습니다.
4. 사용자가 유형을 고르면 초안을 `version-rubric`에 넘깁니다. 파일을 쓰는 것은 `version-rubric`이고 스캔은 아무것도 쓰지 않습니다.

소비자가 여럿이면 유형도 여럿입니다. 이때는 하나를 고르는 대신 주 유형의 초안에 다른 유형의 `## Public Interface` 항목을 합치고 같은 변경에 등급이 갈리면 가장 높은 등급을 씁니다.

### 새 유형 추가

카탈로그에 없는 성격의 프로젝트는 `_template.md`를 복사해 같은 층에 `<id>.md`로 만들고 `INDEX.md` 표에서 소비자가 비슷한 행 옆에 행을 추가합니다. **표에 없는 파일은 스캔이 찾지 못합니다.** 강한 신호는 그 유형에서만 나오는 경로여야 합니다 — `README.md`처럼 어디에나 있는 파일은 신호가 아닙니다.

## 설정값

| 키 | 종류 | 기본값 | clone 전파 | 용도 |
|---|---|---|---|---|
| `JIG_VERSION_RUBRIC` | 환경 변수 | 없음 | 안 됨 (세션 한정) | 일회성 경로 override, CI |
| `jig.versionRubric` | `git config --local` | 없음 | 안 됨 | 관례 경로를 못 쓸 때의 저장소 override |
| (관례 경로) | 파일 | `.jig/versioning.md` | 됨 | 정상 경로 |

해석 순서는 환경 변수 → 로컬 설정 → 관례 경로입니다. `JIG_GITHUB_PROFILE`/`jig.githubProfile` 쌍과 같은 형태입니다.

설정 키에는 **경로만** 넣습니다. "기본 기준을 채택했다" 같은 상태는 파일 상단의 `> Basis:` 줄에만 기록합니다. `git config --local`은 `.git/config`에 저장되어 clone에 전달되지 않으므로 상태를 그쪽에 두면 같은 저장소가 사람마다 다르게 판정합니다.

## 사용법

Claude Code는 `/jig:version-rubric`, Codex와 Antigravity는 `jig-version-rubric`으로 실행합니다. 인자는 없습니다. 스킬이 현재 상태를 먼저 확인한 뒤 무엇을 할지 묻습니다.

| 하고 싶은 것 | 스킬이 하는 일 |
|---|---|
| 지금 기준이 뭔지 보기 | 경로·출처·종류·3등급·커밋 여부를 보고합니다 |
| 처음 정하기 | 기본 기준을 보여주고 "이 기준으로 갈까요?" 하나만 묻습니다 |
| 어떤 유형인지 모르겠을 때 | `rubric-scan`이 저장소를 스캔해 후보를 고르고 이 스킬이 그 초안을 씁니다 |
| **다시 정하기** | 현재 기준을 보여주고 확인을 받은 뒤 교체합니다 |
| 한 등급만 손보기 | 그 등급의 문항과 정의만 바꾸고 나머지는 보존합니다 |
| 기본으로 되돌리기 | 기본 기준 전문으로 교체합니다 |

언제든 다시 실행할 수 있습니다. 프로젝트가 자라면서 기준이 바뀌는 것은 정상이고 파일을 직접 편집해도 됩니다 — 편집한 내용이 곧 새 기준입니다.

설치 직후에는 `jig-setup`이 이 스킬을 대신 호출합니다. 릴리즈 시점에 파일이 없으면 `github-release`가 호출한 뒤 릴리즈를 계속 진행합니다. 질문을 넘기면 기본 기준을 채택한 것으로 기록하고 다시 묻지 않습니다.

## 기본 기준 (사람 개입 축)

스킬이 쓰는 기본 기준 전문입니다. 섹션 제목과 문항이 영어인 이유는 [섹션 제목](#섹션-제목)에 있습니다.

```md
# Version Policy

> Basis: jig default (human-intervention axis), adopted <date>

## Decision Order
1. Is this a fix inside what the project already does? → `patch`
2. Can people do something new, or did a generation turn over, while everything they already do keeps working? → `minor`
3. Did the value on offer widen, shrink, or change, or must a human step in to keep using it? → `major`

## Grade Definitions
| bump | definition |
|---|---|
| `patch` | A fix inside the existing feature set: bug fixes, wording and documentation changes, internal cleanup |
| `minor` | A capability added, removed, or changed, or a generation replaced. Something new is possible and the old way still works |
| `major` | The value on offer widened, shrank, or changed, or a human must edit config, files, or call sites to keep using it |

## Hard Rules
> A change that raises no error but behaves differently is `major`. Its size does not matter.

> A skill or prompt instruction that changes when the agent speaks is at least `minor`.

## Version Format
- While the major version is `0`, a `major` grade raises the minor position: `v0.Y.Z` → `v0.(Y+1).0`. Before 1.0, both the value on offer and the call sites may change at any time. Grade exactly as after 1.0 and record the `major` grade in the release report.
- After `v1.0.0`, a `major` grade raises the major position. The grace above ends there.
```

등급을 변경 규모가 아니라 **사람이 손대야 하는지**로 가릅니다. AI와 함께 만드는 프로젝트는 세대가 빠르게 갈리는데, 규모로 판정하면 세대가 바뀔 때마다 `major`가 되어 숫자가 정보를 잃습니다. 세대 교체는 `minor`로 내려가고 `major`는 제공 가치가 확장·제거·변경되거나 사람이 직접 고쳐야 하는 경우에만 붙습니다.

강경 규칙 두 개가 함께 붙습니다. 프롬프트와 지시문은 테스트로 검증되지 않아서 문구 한 줄이 에이전트의 발화 조건을 조용히 바꿔도 CI가 잡지 못합니다. 그래서 조용한 동작 변경을 버전으로 알립니다.

`0.x`인 동안에는 `minor`와 `major`가 같은 자리(`v0.(Y+1).0`)로 착지하므로 이 규칙들이 숫자를 바꾸지 않습니다. 1.0이 아니라는 것 자체가 "언제든 바뀔 수 있다"는 뜻이고 규칙은 `v1.0.0`부터 실제로 물립니다. 필요 없으면 두 섹션을 지우면 됩니다 — 계약상 둘 다 선택입니다.

## 파일 계약

필수 섹션 2개, 선택 4개입니다. **섹션 제목이 계약입니다.**

| 섹션 | 필수 | 내용 |
|---|---|---|
| `## Decision Order` | 필수 | 순서대로 묻는 질문 3개와 각 등급 |
| `## Grade Definitions` | 필수 | 등급별 정의 표 |
| `## Hard Rules` | 선택 | 무조건 승격시키는 조건 |
| `## Release Notes` | 선택 | 노트 섹션 순서·제목 override |
| `## Version Format` | 선택 | 태그 정규식, 1.0 이전 처리, 요약 언어 |
| `## Pre-Release Checks` | 선택 | 릴리즈 전에 실행할 명령 |

- `## Decision Order`는 순서대로 묻고 **처음 걸리는 곳에서 멈춥니다.** 이 의미는 기준 파일이 바꿀 수 없습니다.
- 기준 파일에 없는 선택 섹션은 그 프로젝트에 적용되지 않습니다. `## Hard Rules`를 지우면 승격 규칙이 없는 것이고 기본 기준의 규칙이 대신 적용되지는 않습니다.

### 섹션 제목

계약 제목은 영어입니다. 스킬 본문이 전부 영어라 제목만 한글이면 같은 파일 안에서 어휘가 갈리고 설치본이 어느 쪽을 써야 하는지 매번 판단해야 합니다.

**한글 제목으로 쓰인 기존 기준 파일은 그대로 동작합니다.** rubric을 읽는 모든 스킬(`github-release`, `jig-doctor`, `version-rubric`, `rubric-scan`)이 양쪽 철자를 모두 인식합니다.

| 영어 (표준) | 한글 (레거시) |
|---|---|
| `## Decision Order` | `## 판정 순서` |
| `## Grade Definitions` | `## 등급 정의` |
| `## Hard Rules` | `## 강경 규칙` |
| `## Release Notes` | `## 릴리즈 노트` |
| `## Version Format` | `## 버전 형식` |
| `## Pre-Release Checks` | `## 릴리즈 전 검증` |
| `> Basis:` | `> 기준:` |

- 한 파일 안에서 두 철자를 **섞지 마세요.** `## Decision Order`와 `## 등급 정의`가 함께 있으면 필수 섹션 하나가 없는 것으로 읽힙니다.
- 스킬은 기존 파일의 제목을 스스로 바꾸지 않습니다. 바꾸고 싶으면 `version-rubric`에 "제목을 영어로 바꿔줘"라고 요청하면 제목만 갈아끼우고 문항은 한 글자도 건드리지 않습니다.
- **문항과 정의는 프로젝트의 언어로 씁니다.** 제목만 계약이고 안의 내용은 그 저장소를 읽는 사람의 말이 정답입니다.
- 계약에 없는 섹션을 추가해도 됩니다. 판정 맥락으로 함께 읽습니다. 예를 들어 "무엇이 우리 프로젝트의 공개 인터페이스인가" 목록을 둘 수 있습니다.
- 필수 섹션이 없거나 판정 순서가 3단계가 안 되면(두 철자 모두 없을 때) `github-release`가 릴리즈를 멈추고 이 스킬을 안내합니다. 깨진 기준으로 조용히 판정하는 것보다 멈추는 게 낫습니다.

## 릴리즈 노트 섹션

노트 섹션은 커밋 prefix에서 자동으로 파생됩니다. 설정할 필요가 없습니다.

| 커밋 prefix | 섹션 |
|---|---|
| `feat:` | `🚀 Enhancements` |
| `fix:` | `🐛 Fixes` |
| `chore:` | `🧰 Chores` |
| 그 밖의 prefix | 그 이름으로 섹션 생성 (`docs:` → `📚 Documentation`) |

문서 위주 프로젝트에서 `docs:` 커밋이 "잡일" 칸으로 밀리지 않습니다. 순서나 제목을 바꾸고 싶으면 `## Release Notes` 섹션에 적습니다.

## 작성 예

### 개발 프로젝트

기본 기준 그대로 쓰면 됩니다. 기존 기능 범위 안의 수정은 `patch`, 기능 추가·삭제·변경과 세대 교체는 `minor`, 제공 가치가 확장·제거·변경되거나 사람이 손대야 하면 `major`입니다.

### 문서 관리 프로젝트

카탈로그의 `document-archive.md`가 이 경우입니다. 직접 쓰면 이런 모양이 됩니다.

```md
# 버전 정책

> Basis: 직접 작성, <날짜>

## Decision Order
1. 문서를 추가·수정·삭제했는가? → `patch`
2. 문서를 관리하는 기능이 추가·수정·삭제됐는가? → `minor`
3. 프로젝트 전체 구조가 대대적으로 바뀌었는가? → `major`

## Grade Definitions
| bump | 정의 |
|---|---|
| `patch` | 문서 콘텐츠 변경. 추가·수정·삭제를 모두 포함 |
| `minor` | 문서를 만들고 관리하는 도구·템플릿·스크립트의 변경 |
| `major` | 디렉토리 구조, 분류 체계, 발행 방식의 전면 개편 |
```

제목은 영어, 문항은 한국어입니다. 계약은 제목뿐이라 이렇게 섞는 게 정상입니다.

### 설치본을 가진 도구

jig 자신이 이 경우입니다. [`.jig/versioning.md`](../.jig/versioning.md)를 참고하세요. 판정 축이 "설치본이 치르는 비용"이고 기본과는 다른 강경 규칙 두 개("조용한 동작 변경은 `major`", "`migration-manual` 블록이 있으면 `major`")와 공개 인터페이스 목록을 함께 둡니다.

## 관련 문서

- [기준 카탈로그 색인](../skills/version-rubric/rubrics/INDEX.md)
- [공통 SemVer 원칙](../skills/version-rubric/rubrics/common.md)
- [jig 버전 정책 해설](versioning.ko.md)
- [설치 가이드](installation.ko.md)
