# 프로젝트별 버전 판정 기준 설계

> 상태: 구현 완료 (2026-08-19)
> 다음 릴리즈 영향: 새 스킬 1종 + 유도된 파괴 → `minor`. `v0.6.0` → **`v0.7.0`**
> 이후 변경: 기본 기준이 "변경 규모 축"에서 "사람 개입 축"으로 교체됐습니다 (2026-08-20). 아래 본문의 기본 기준 인용은 당시 설계 기록이며, 현행 기본은 [버전 판정 기준](../../version-rubric.md)에 있습니다.

버전 판정 기준 = `patch`/`minor`/`major`를 무엇으로 가를지 적어둔 규칙. 현재 `github-release` 스킬 본문에 고정돼 있고, 이 설계는 그것을 프로젝트 소유 파일로 옮긴 뒤 전용 스킬로 관리한다.

## 문제

배포되는 판정 기준이 **SPAI 자신의 도메인에 고정**돼 있다. `skills/github-release/SKILL.md:28` — "The bump is decided by what an installed project actually pays... The primary consumer of a release note is the `spai-update` skill". 이 축은 "배포되는 도구 + 그것을 소비하는 설치본"의 존재를 전제한다.

설치된 프로젝트에는 그런 소비자가 없다. 그래서 판정 축이 어긋난다.

| | 판정 축 | 구분 근거 |
|---|---|---|
| SPAI 현재 (배포 중) | 설치본이 치르는 비용 | 무인 복구 가능한가, 실패가 시끄러운가 조용한가 |
| 개발 프로젝트 | 변경 규모 | 단순 변경 / 큰 기능 추가·삭제·수정 / 세대 전환 |
| 문서 관리 프로젝트 | 산출물 종류 | 문서 콘텐츠 / 문서 관리 기능 / 프로젝트 구조 |

임계값 차이가 아니라 축 자체가 다르므로, 옵션 몇 개를 뚫는 방식으로는 해결되지 않는다.

### 현행 규칙이 두 프로젝트에서 오작동하는 지점

| 위치 | 개발 프로젝트 | 문서 관리 프로젝트 |
|---|---|---|
| `SKILL.md:44` "조용한 동작 변경은 무조건 `major`" | 단순 기능 변경도 강제 `major` (원함: `patch`) | — |
| `major` 정의 "사용자 파일 삭제" | 큰 기능 삭제가 `major` (원함: `minor`) | 문서 삭제가 `major` (원함: `patch`) |
| 판정 순서 1번 "설치본이 아무것도 안 해도 됨 → `patch`" | 세대 전환·가치 변화가 `patch`로 강등 | 구조 대개편이 `patch`로 강등 |
| `SKILL.md:78-80` `migration-manual` → 강제 `major` | 큰 기능 변경마다 `major`로 튐 | 설치본이 없어 영구 미발동 → `major` 도달 경로 부재 |
| `SKILL.md:133-137` 노트 섹션 매핑 | 대체로 맞음 | 주력 변경(`docs:`)이 전부 `🧰 Chores`로 |
| `SKILL.md:82-92` Public Interface 목록 | 해당 항목 0개 → 판정 입력이 공백 | 동일 |
| `SKILL.md:145` `sh scripts/validate-dist.sh` | SPAI 전용 스크립트 | 동일 |
| `SKILL.md:98` `docs/versioning.md` 포인터 | dist에 없음(`find dist -name "versioning*"` → 0건) → 끊긴 링크 | 동일 |

### 회피가 불가능한 이유

- `--skills`로 `github-release`를 통째 제거하는 것만 가능하다(all-or-nothing). 게다가 migration 블록 *작성자*가 사라져 `spai-update`가 기대하는 계약이 끊긴다.
- 설치본 `SKILL.md`를 직접 고치면 `skills/spai-doctor/SKILL.md:30-33`이 "locally modified" 결함으로 보고하고, `install.sh:334-372`가 다음 업데이트에 덮어쓴다.

## 해결 방향

세 조각으로 나눈다.

1. **파일** — 판정 기준을 프로젝트 소유 `.spai/versioning.md`로 옮긴다. SPAI는 그 경로를 소유하지 않는다.
2. **기본값** — SPAI가 기본 기준 하나를 제시한다. 사용자의 결정은 이진이다: 따를지, 직접 쓸지.
3. **스킬** — `version-rubric` 스킬이 그 파일의 생성·조회·재설정을 전담한다. 언제든 다시 실행할 수 있다.

`SKILL.md:98`이 이미 `docs/versioning.md`를 가리키고 있다. 설치된 프로젝트에서 에이전트가 이 줄을 읽으면 **그 프로젝트의** 파일을 찾는다. 지금은 끊긴 링크지만, 이것을 명시적 계약으로 승격하는 것이 출발점이다.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 판정 기준 위치 | `.spai/versioning.md`. 프로젝트 소유. SPAI는 경로를 **소유하지 않는다** |
| 경로 override | `SPAI_VERSION_RUBRIC`(세션) → `git config --local spai.versionRubric`(저장소) → 관례 경로 |
| `docs/` 탐색 제외 | 문서 관리 프로젝트의 `docs/versioning.md`는 자기 제품 콘텐츠일 수 있어 오인 위험 |
| 형식 | 사람이 읽는 Markdown + 고정 섹션 제목. 파서 없음, 에이전트가 읽고 적용 |
| **선택지** | **기본 따름 / 직접 작성. 둘뿐이다.** 프리셋 카탈로그도, 축 분류도 만들지 않는다 |
| 기본 기준 | **변경 규모 축** 1종. `version-rubric` 스킬 본문에 전문을 싣는다. `github-release`에는 스킬 미설치 시에만 쓰는 3문항 fallback만 둔다 |
| 미결정 상태 | 없다. 어느 쪽을 골라도 파일이 만들어지고, 파일 존재 = 결정 완료 |
| 파일 부재 시 | 판정을 멈추지 않고 선택을 유도한 뒤 계속 진행한다 |
| 부분 override | 섹션 단위. 없는 섹션은 기본 기준의 해당 섹션을 쓴다 |
| **전용 스킬** | `version-rubric` 신설. 파일의 생성·조회·재설정·부분 수정·기본 복귀를 전담 |
| 재실행 | 언제든 가능. 스킬을 다시 호출하면 현재 기준을 보여주고 유지·교체·수정을 고른다 |
| 상태 저장 위치 | 파일 **안에만** 둔다. config 키에 "기본 채택했음" 같은 상태를 쓰지 않는다 |
| Migration 블록 문법 | 유지. 단 "`migration-manual` → 강제 `major`"는 SPAI 자신의 기준 파일로 이동 |
| 노트 섹션 매핑 | 표를 없애고 **커밋 prefix에서 자동 파생** |

### 왜 이진 선택인가

프리셋을 3종 이상 두면 사용자가 먼저 "내 프로젝트는 어느 축인가"를 판단해야 한다. 그 판단이 이 기능의 진입 비용 전부다. 기본 기준 하나를 보여주고 "이대로 갈까?"만 물으면, 판단이 **읽고 동의하기**로 줄어든다. 안 맞는 사람만 자기 문장으로 고친다.

카탈로그를 없애는 대가는 문서 관리 프로젝트가 기본을 못 쓰고 직접 작성 경로로 간다는 것이다. 그쪽 경로에 기본 기준이 초안으로 주어지므로 백지에서 시작하지 않는다.

### 왜 스킬 본문에 판정 기준을 숨겨두지 않는가

숨은 기본값으로 판정하면 **어떤 기준이 쓰였는지 저장소 어디에도 남지 않는다.** 사용자는 자기 기준이 안 쓰이고 있다는 사실조차 모른다. 그래서 기본값을 없애는 대신 밖으로 꺼낸다: 기본을 따르기로 하면 그 내용을 파일에 그대로 쓴다.

- 파일이 항상 생기므로 매 릴리즈마다 다시 묻지 않는다.
- 어떤 기준으로 판정되는지가 커밋 diff로 보인다.
- 나중에 그 파일을 고치면 그게 곧 결정 변경이다.

### 왜 전용 스킬인가

앞선 검토에서는 `project-setup`의 한 단계로 두려 했다(roadmap A의 "선제작 금지" 원칙). 뒤집는다. 근거 셋:

1. **호출자가 3개다** — `project-setup`(설치 직후), `github-release`(판정 직전), `spai-doctor`(진단 후 안내). 절차를 한 스킬 안에 두면 나머지 둘이 그 스킬의 내부 단계를 지목해야 한다.
2. **재실행이 요구사항이다** — 기준은 프로젝트가 자라면서 바뀐다. 사용자가 "판정 기준 다시 잡자"고 할 때 부를 이름이 있어야 한다. `project-setup`을 다시 돌리는 것은 GitHub 프로필·설치 검증까지 재실행하는 과잉이다.
3. **소유 경계가 깔끔해진다** — 기준 파일을 쓰는 스킬이 하나뿐이면 "누가 이 파일을 고칠 수 있나"에 답이 하나다.

## 설정값

| 키 | 종류 | 기본값 | clone 전파 | 용도 |
|---|---|---|---|---|
| `SPAI_VERSION_RUBRIC` | 환경 변수 | 없음 | — (세션 한정) | 일회성 경로 override. CI나 실험용 |
| `spai.versionRubric` | `git config --local` | 없음 | **안 됨** | 관례 경로를 못 쓸 때의 저장소 override |
| (관례 경로) | 파일 | `.spai/versioning.md` | 됨 | 정상 경로 |

해석 순서: 환경 변수 → local config → 관례 경로. 기존 `SPAI_GITHUB_PROFILE`/`spai.githubProfile` 쌍과 같은 형태다(`skills/github-sync/SKILL.md:21`).

**config 키에는 상태를 쓰지 않는다.** "기본을 채택했다", "직접 작성했다" 같은 정보는 파일 상단 `> 기준:` 줄에만 둔다. 이유: `git config --local`은 `.git/config`에 저장되어 clone·CI 체크아웃에 전파되지 않는다. 상태를 그쪽에 두면 같은 저장소가 사람마다 다른 기준으로 판정된다. 경로 override만 config에 두는 것은 그 자체가 "이 환경에서만"이라는 뜻이므로 일관된다.

## 파일 위치

```text
.spai/
└── versioning.md      # 버전 판정 기준 (이 설계가 정의하는 유일한 파일)
```

- **`.spai/`는 프로젝트가 소유하는 SPAI 설정 자리다.** SPAI 스킬이 읽지만, installer와 `spai-update`는 이 디렉토리를 쓰지도 지우지도 않는다.
- `spai-doctor`의 드리프트 `cmp` 대상이 아니다. 사용자가 고친 것이 정답이다.
- **`.gitignore`에 넣지 않는다.** 커밋되어야 clone·CI·다른 기여자에게 전파된다. 커밋되지 않은 상태는 `spai-doctor`가 경고한다.
- 향후 브랜치 모델·보호 정책 파라미터화(roadmap **C**·**D**)가 이 디렉토리 아래로 들어올 자리지만, **이번 설계는 `versioning.md` 하나만 만든다.** 쓰이지 않는 파일을 미리 만들지 않는다.

## 기본 기준 (변경 규모 축)

```md
# 버전 정책

> 기준: SPAI 기본 (변경 규모 축), <날짜> 채택

## 판정 순서
1. 기존 기능의 단순 변경·수정인가? → `patch`
2. 기능이 추가·삭제되거나 크게 바뀌었는가? → `minor`
3. 프로젝트가 제공하는 가치나 세대가 바뀌었는가? → `major`

## 등급 정의
| bump | 정의 |
|---|---|
| `patch` | 기존 기능 범위 안의 수정. 버그 수정, 문구·문서 변경, 내부 구현 정리 |
| `minor` | 기능 단위의 추가·삭제·변경. 사용자가 새로 할 수 있는 일이 생기거나 없어짐 |
| `major` | 프로젝트의 방향·구조·제공 가치가 바뀜. 이전 버전과 같은 것으로 설명되지 않음 |
```

강경 규칙은 두지 않는다. 이 축에서 "조용한 동작 변경"은 별도 승격 사유가 아니다 — 그건 설치본을 가진 도구에만 의미가 있고, SPAI 자신의 기준 파일에서만 쓴다.

다른 축이 필요한 예: 문서 관리 프로젝트는 `patch`=문서 추가·수정·삭제 / `minor`=문서 관리 기능 변경 / `major`=구조 개편. 직접 작성 경로에서 이렇게 쓴다.

## 판정 기준 파일 계약

필수 섹션 2개, 선택 3개. 제목 문자열이 계약이다.

```md
# 버전 정책

> 기준: SPAI 기본 (변경 규모 축) | 직접 작성, <날짜>

## 판정 순서        (필수)
1. <질문> → `patch`
2. <질문> → `minor`
3. <질문> → `major`

## 등급 정의        (필수)
| bump | 정의 |

## 강경 규칙        (선택) 무조건 승격시키는 조건
## 릴리즈 노트      (선택) 섹션 순서·제목 override
## 버전 형식        (선택) 태그 정규식, 1.0 이전 처리, 요약 언어
## 릴리즈 전 검증    (선택) 릴리즈 전에 실행할 명령
```

- `## 판정 순서`는 순서대로 묻고 **처음 걸리는 곳에서 멈춘다.** 이 의미는 기준 파일이 바꿀 수 없는 고정 규칙이다.
- 없는 선택 섹션은 기본 기준의 규칙을 쓴다. `## 강경 규칙`이 없으면 승격 규칙 없이 판정 순서만 쓴다.
- 상단 `> 기준:` 줄은 기본 채택인지 직접 작성인지를 남긴다. `version-rubric`과 `spai-doctor`가 읽는다.
- 계약에 없는 섹션을 추가해도 무시하지 않고 판정 맥락으로 읽는다. SPAI 자신의 기준 파일이 `## 공개 인터페이스`를 그렇게 쓴다.

### 노트 섹션 자동 파생

표 대신 규칙 한 줄로 처리한다.

> 커밋 prefix별로 섹션을 만든다. `feat`→`🚀 Enhancements`, `fix`→`🐛 Fixes`, `chore`→`🧰 Chores`는 기존 제목을 쓰고, 나머지 prefix는 그 이름으로 섹션을 만든다(`docs:`→`📚 Documentation`).

문서 프로젝트가 아무 설정을 안 해도 `docs:`가 잡일 칸으로 가지 않는다.

## 새 스킬: `version-rubric`

```yaml
name: version-rubric
description: >
  Use when creating, reviewing, or re-setting this repository's version grading
  rubric at .spai/versioning.md: adopt the SPAI default change-scale rubric,
  write a project-specific one, edit one grade, or reset to the default.
  Owns the rubric file; never runs a release.
```

호출: `/spai:version-rubric` (Claude Code), `spai-version-rubric` (Codex/Antigravity)

### 동작 5종

인자 없이 호출한다. 스킬이 상태를 먼저 판정하고 사용자 의도를 확인해 분기한다.

| 동작 | 조건 | 결과 |
|---|---|---|
| 조회 | 파일 있음 | 현재 기준 요약(출처·종류·3등급·커밋 여부) 출력, 끝 |
| 생성 | 파일 없음 | 기본 기준 제시 → 이진 선택 → 파일 생성 |
| **재설정** | 파일 있음 + 사용자가 교체 요청 | 현재 기준을 보여주고 확인 → 새 기준으로 교체 |
| 부분 수정 | 파일 있음 + 한 등급만 손보고 싶을 때 | 해당 등급의 판정 문항·정의만 갱신, 나머지 보존 |
| 기본 복귀 | 파일 있음 + 기본으로 되돌리기 요청 | 기본 기준 전문으로 교체, 상단 줄도 기본 채택으로 갱신 |

### 절차

1. 경로 해석(환경 변수 → local config → `.spai/versioning.md`)과 상태 판정.
2. 파일이 있으면 현재 기준을 요약해 보여주고, 유지·재설정·부분 수정·기본 복귀 중 무엇인지 확인한다. 유지면 여기서 끝난다.
3. 파일이 없거나 재설정이면 **기본 기준 전문을 보여주고 "이 기준으로 갈까?"** 를 묻는다.
   - 예 → 기본 기준을 파일로 쓰고 상단에 기본 채택으로 기록.
   - 아니오 → 세 등급에 각각 "이 프로젝트에서 어떤 변경이 여기 해당하는가"를 묻고, 사용자가 쓴 표현을 그대로 `## 판정 순서`·`## 등급 정의`에 넣는다.
4. 응답이 없거나 사용자가 넘기면 기본 채택으로 처리한다. 되묻지 않는다.
5. 파일을 쓰고 커밋을 위임한다. `readme` 스킬의 병합 패턴을 그대로 쓴다(`skills/readme/SKILL.md` 5번): `develop-task-flow`(또는 `spai-develop-task-flow`)가 있으면 `chore/<slug>` 브랜치 → `chore:` squash 커밋 → `develop` push. 없으면 일반 커밋을 제안한다.
6. 보고: 경로, 출처, 기준 종류, 바뀐 등급, 커밋 상태.

3번에서 사용자 표현을 SPAI 어휘로 번역하지 않는 것이 중요하다. "세대 전환", "구조 대개편" 같은 말이 "조용한 동작 변경" 따위로 치환되면 다음 릴리즈에서 판정이 흔들린다. 문장 형태만 `→ patch` 꼴로 맞춘다.

### 안전 규칙

- 기존 기준 파일을 **사용자 확인 없이 덮어쓰지 않는다.** 재설정·기본 복귀는 현재 내용을 먼저 보여주고 확인받는다.
- `.bak`을 만들지 않는다. 파일은 tracked이므로 git 히스토리가 이력이다. 단 파일이 untracked거나 커밋되지 않은 변경이 있으면 덮어쓰기 전에 경고한다.
- 판정을 실행하지 않는다. 릴리즈 판정과 노트 작성은 `github-release`가 소유한다.
- 저장소 설정·브랜치·보호 규칙·릴리즈를 건드리지 않는다.
- `.spai/` 밖에 파일을 만들지 않는다.
- 커밋을 강제하지 않는다. 사용자가 거절하면 미커밋 상태를 보고한다.

### 배포 통합

- `manifest.tsv`에 `version-rubric	solo-cli	yes` 추가
- `scripts/build-dist.sh`의 `skill_summary()`에 case 추가: "프로젝트의 버전 판정 기준 파일을 만들거나 다시 설정한다."
- `sh scripts/build-dist.sh` 재생성 → `dist/codex`·`dist/antigravity`에 `spai-version-rubric`, Claude Code 플러그인에 `version-rubric`
- 저장소 사본 동기화: `.agents/skills/spai-version-rubric/`, `.claude/skills/version-rubric/`
- installer는 manifest 기반이라 코드 변경 없음 (구현 시 확인)

## 진입점

| 시점 | 스킬 | 동작 |
|---|---|---|
| 설치 직후 | `project-setup` | `version-rubric`을 위임 호출. 사용자가 넘기면 기본 채택으로 기록 |
| 릴리즈 직전 | `github-release` | 파일이 없으면 `version-rubric`을 위임 호출하고 **계속 진행**한다 |
| 진단 시 | `spai-doctor` | 출처·종류·필수 섹션·커밋 여부를 보고. fix owner는 `version-rubric` |
| **언제든** | `version-rubric` | 사용자가 직접 호출. 조회·재설정·부분 수정·기본 복귀 |

`install.sh`는 관여하지 않는다. installer는 `curl | sh` 비대화 실행이 기본이고(README: 기본 설치 중 prompt 없음), Claude Code 경로에는 installer가 아예 없다. 셸에 두면 Claude Code 사용자는 이 단계를 영원히 못 만난다.

### 스킬 부분 설치 시

`--skills`로 `version-rubric`을 제외한 설치도 가능하다. 그때 `github-release`는 위임 대상이 없으므로, **기본 기준을 적용하고 그 사실을 보고한 뒤 판정을 계속한다.** 파일을 만들지 않고 릴리즈를 막지도 않는다. 스킬을 나중에 설치하면 그때 파일이 생긴다.

## 스킬별 변경

### `github-release`

1. `## Version Policy` 섹션을 **판정 기준 해석 계약**으로 교체: 경로 해석 순서, 섹션 단위 부분 override, 파일 부재 시 `version-rubric` 위임 후 계속, 스킬 미설치 시 기본 적용 + 보고.
2. **판정 규칙 본문 삭제** — 판정 순서 3문항, 등급 표, 강경 규칙, `## Public Interface` 목록, `sh scripts/validate-dist.sh`. 전부 SPAI 자신의 `.spai/versioning.md`로 옮겨진다. 배포본에서 사라지고 SPAI 자신의 판정은 동일하게 유지된다.
3. 노트 섹션 매핑 표를 자동 파생 규칙 1줄로 교체.
4. 8번 검증 단계 일반화: 기준 파일의 `## 릴리즈 전 검증` 섹션 또는 저장소 관례에서 명령을 찾고, 없으면 건너뛰고 보고한다.
5. `migration-manual` → `major` 강제를 SPAI 자신의 기준 파일 `## 강경 규칙`으로 이동. Migration 블록 **문법**은 그대로 남긴다.

### `project-setup`

- 절차에 판정 기준 단계 추가: 파일이 있으면 출처와 종류만 보고, 없으면 `version-rubric` 위임.
- 넘기거나 응답이 없으면 기본 채택으로 기록한다.
- 기준 파일 내용을 이 스킬 본문에 중복해 싣지 않는다. 전문은 `version-rubric`에만 있다.

### `spai-doctor`

체크 항목 하나를 추가한다(read-only 유지).

- 출처: `SPAI_VERSION_RUBRIC` | `spai.versionRubric` | `.spai/versioning.md` | 파일 없음
- 기준 종류: 기본 채택 | 직접 작성 (상단 `> 기준:` 줄)
- 필수 섹션(`## 판정 순서`, `## 등급 정의`) 존재 여부
- 커밋 여부(`git ls-files --error-unmatch`). 미커밋은 경고 — clone에 전파되지 않는 상태다
- 경로 override가 환경 변수에서 왔다면 세션 한정임을 명시
- 파일 부재는 결함이 아니라 정보. fix owner는 `version-rubric`
- 기준 파일은 드리프트 `cmp` 대상이 아님을 명시

### `spai-update`

절차 변경 없음. `.spai/`가 installer 소유가 아니어서 업데이트가 덮어쓰지 않는다는 문장만 Update Model에 추가한다.

### `develop-task-flow`

커밋 타입이 노트 섹션으로 자동 파생된다는 문장 1줄 추가. 커밋 본문 언어 규칙은 이번 범위 밖.

## 문서

- **`docs/version-rubric.md` 신설** — 기준 파일의 섹션 계약, 기본 기준 전문, 설정값 표, `version-rubric` 사용법(조회·재설정·부분 수정·기본 복귀), 두 예시 프로젝트의 작성 예. README에서 링크한다.
- **`README.md`** — 스킬 표에 `version-rubric` 행 추가, 설치 후 절차에 "판정 기준 선택" 한 줄, 새 문서 링크.
- **`docs/versioning.md`** — SPAI 자신의 정책 해설로 남기고, 규범 원본은 `.spai/versioning.md`임을 상단에 명시해 서로 링크한다.
- `develop-task-flow`의 문서 규칙(설치 동작·사용자 워크플로 변경 시 같은 태스크에서 README 갱신)을 따른다.

## 예시 프로젝트 대조

| 요구 | 표현 방법 |
|---|---|
| 개발: 단순 기능 변경 = `patch` | 기본 기준 판정 순서 1번. 강경 규칙이 없으므로 "조용한 동작 변경 → `major`"에 걸리지 않는다 |
| 개발: 큰 기능 추가·삭제·수정 = `minor` | 기본 기준 2번. "사용자 파일 삭제 = `major`" 예시가 등급 정의에 없다 |
| 개발: 세대 전환·가치 변화 = `major` | 기본 기준 3번. 소비자 비용이 아니라 규모를 묻기 때문에 `patch`로 강등되지 않는다 |
| 문서: 문서 추가·수정·삭제 = `patch` | 직접 작성 경로. `patch` 답변으로 들어간다 |
| 문서: 문서 관리 기능 = `minor` | 같은 경로, `minor` 답변 |
| 문서: 구조 대개편 = `major` | 같은 경로, `major` 답변. `migration-manual` 강제 규칙을 안 쓰므로 도달 가능 |
| 문서: `docs:` 커밋이 잡일 칸으로 안 가게 | 자동 파생으로 `📚 Documentation` 섹션 생성, 설정 불필요 |
| 둘 다: 나중에 기준을 바꾸고 싶다 | `version-rubric` 재호출 → 재설정 또는 부분 수정 |

개발 프로젝트는 기본 그대로 통과하고, 문서 프로젝트만 질문 3개에 답한다.

## 검증

- `scripts/validate-dist.sh`에 추가:
  - `version-rubric` 배포본 3곳 존재 확인(`dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md`, `dist/codex/.agents/skills/spai-version-rubric/SKILL.md`, antigravity 동일)
  - `github-release`·`project-setup`·`spai-doctor`·`version-rubric` 배포본에 계약 문자열(`.spai/versioning.md`, `## 판정 순서`) 존재 확인
  - `version-rubric` 배포본에 기본 기준 3등급 문항이 모두 있는지 확인
  - **negative 가드**: 배포본 `github-release`에 `scripts/validate-dist.sh`, `spai@spai`, `0x0w1/spai`, `--target` 문자열이 없어야 한다. 자기 사실 누출의 재발 방지
  - **negative 가드**: `project-setup` 배포본에 기본 기준 전문이 중복되지 않아야 한다
- 회귀 확인: SPAI 자신의 `.spai/versioning.md`로 `docs/versioning.md`의 적용 예 2건(`v0.2.0` → `major`, `v0.2.1` → `minor`)을 재판정해 동일한지 확인
- 기본 기준 검증: 대조표의 개발 프로젝트 3건이 기본 기준만으로 기대 등급이 나오는지 확인
- 직접 작성 검증: 문서 프로젝트 3건을 질문 3개 경로로 작성해 기대 등급이 나오는지 확인
- 재실행 검증: 기본 채택 → 재설정(직접 작성) → 부분 수정 → 기본 복귀를 순서대로 실행해 매번 파일이 일관되게 갱신되고 확인 절차가 빠지지 않는지 확인
- 부분 설치 검증: `--skills`에서 `version-rubric`을 뺀 설치에서 `github-release`가 기본 적용 + 보고로 진행되는지 확인
- `sh scripts/validate-dist.sh` 통과, 저장소 내 사본 3곳(`skills/`, `.agents/skills/`, `.claude/skills/`) 동기화

## 릴리즈 영향

- **등급: `minor`.** 새 스킬 1종 추가(새 capability)이고, 판정 축 변경은 사용 지점에서 시끄럽다 — 선택이 유도되고, 채택된 기준이 릴리즈 보고에 찍히고, `.spai/versioning.md`가 tracked file로 생겨 diff에 보인다. 사람의 결정이 강제되는 항목은 없다(넘기면 기본 채택).
- 판정 순서 적용: 1번(설치본 무조치) 불통과 — 판정 결과가 달라진다. 2번(b) 통과 — 실패 지점에서 대체 수단을 제시한다 → `minor`.
- `Migration` 섹션 없음 → 노트가 강제하는 최소 등급도 `minor`. 등급과 노트가 일치한다.
- `migration-auto`: 없음. `spai-update`가 남의 저장소에 기준 파일을 만들지 않는다. 파일 생성은 `version-rubric` 대화 안에서만 일어난다.
- 공개 인터페이스 추가분: 스킬 이름 `version-rubric`, 파일 경로 `.spai/versioning.md`, 설정 키 `SPAI_VERSION_RUBRIC`·`spai.versionRubric`, 섹션 제목 `## 판정 순서`·`## 등급 정의`. 다음 릴리즈부터 이들이 깨지면 최소 `minor`다.
- `v0.6.0` → **`v0.7.0`**.
- SPAI 자신은 이 릴리즈에서 `.spai/versioning.md`를 만든다: 현행 소비자비용 축 + 강경 규칙 2개("조용한 동작 변경은 `major`", "`migration-manual`이 있으면 `major`") + Public Interface 목록.

## 범위 밖

- 브랜치 이름·브랜치 prefix·병합 방식·branch protection 기대값의 파라미터화 (roadmap 후보 **C**·**D**). `.spai/` 아래가 그 자리지만 이번에는 파일을 만들지 않는다
- 커밋 본문 언어와 릴리즈 노트 `### Summary` 언어의 파라미터화
- 기준 파일의 기계 파서·스키마 검증 (지금은 에이전트가 읽는 프로즈)
- 기준 축 카탈로그·프리셋 배포 (`references/` 디렉토리 지원 포함)
- 기준 변경 이력 관리 (git 히스토리로 충분)
- `spai-doctor`의 branch protection 기대값 고정 문제 (별건)

## 열린 질문

1. 기본 채택으로 만든 파일을 **커밋까지 자동으로** 할지. 커밋하지 않으면 clone에 전파되지 않아 사람마다 기준이 갈린다. 지금 결정은 `readme` 패턴대로 커밋을 제안하고, 미커밋 상태는 `spai-doctor`가 경고하는 것.
2. `version-rubric`이 **판정 시뮬레이션**을 제공할지. "최근 커밋 3개를 이 기준으로 판정하면 뭐가 나오나"를 보여주면 기준이 의도대로 동작하는지 즉시 검증된다. 스킬 분량과 `github-release`와의 경계가 흐려지는 비용이 있다. 지금은 범위 밖.
3. 기준 파일이 계약을 어겼을 때(필수 섹션 누락, 판정 순서가 2단계뿐) `github-release`가 **멈출지 기본으로 대체할지.** 지금 결정은 멈추고 `version-rubric`을 안내하는 것 — 깨진 기준으로 조용히 판정하는 것보다 낫다.

## 구현 결과 (2026-08-19)

`feature/version-rubric`에서 구현했다. 설계와 달라진 점만 기록한다.

- `## 릴리즈 전 검증`을 선택 섹션으로 확정해 계약이 필수 2 + 선택 4가 됐다. SPAI 자신의 기준 파일이 `sh scripts/validate-dist.sh`를 여기 담고, `github-release` 8번 단계가 그것을 읽는다.
- 계약에 없는 섹션도 판정 맥락으로 읽는 규칙을 추가했다. SPAI의 공개 인터페이스 목록이 `## 공개 인터페이스`로 기준 파일에 들어갔다.
- `github-release`에는 판정 규칙 대신 3문항 fallback만 남겼다. `version-rubric`이 설치되지 않은 부분 설치에서만 쓰인다.
- 버전 산식(`^v[0-9]+\.[0-9]+\.[0-9]+$`, 1.0 이전 자리 올림)은 `## Version Format` 기본값으로 스킬에 남기고 `## 버전 형식`으로 override하게 했다. semver 산술은 도메인 지식이 아니라 기계적 규칙이라 프로젝트마다 다시 정할 이유가 없다.
- `validate-dist.sh`에 negative 가드를 넣었다: 배포본 `github-release`에 `scripts/validate-dist.sh`·`spai@spai`·`0x0w1/spai`·`--target`이 없어야 하고, `project-setup`이 기본 기준 문항을 복제해서는 안 된다.
