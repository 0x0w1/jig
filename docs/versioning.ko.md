# 버전 정책

[English](versioning.md)

> 이 문서는 사람이 읽는 해설입니다. jig 릴리즈 판정의 규범 원본은 [`.jig/versioning.md`](../.jig/versioning.md)이고 `github-release`가 릴리즈할 때 읽는 파일도 그쪽입니다. 두 파일은 같은 내용을 말해야 합니다.
>
> 다른 프로젝트에 설치된 jig는 그 프로젝트의 `.jig/versioning.md`를 읽습니다. 판정 기준을 만들거나 다시 잡는 방법은 [버전 판정 기준](version-rubric.ko.md)에 있습니다.

jig의 `vX.Y.Z` bump는 **변경의 종류**가 아니라 **설치본이 실제로 치르는 비용**으로 결정합니다. 릴리즈 노트의 주 소비자가 사람이 아니라 `jig-update` 스킬이기 때문에 에이전트가 무인으로 처리할 수 있는 변경과 사람의 판단이 필요한 변경을 같은 등급으로 묶지 않습니다.

## 판정 순서

질문 세 개를 순서대로 던지고 처음 걸리는 곳에서 멈춥니다.

1. 설치본이 아무것도 하지 않아도 되거나 업데이트 재실행만으로 수렴하는가? → `patch`
2. 깨지긴 하지만 (a) `jig-update`가 무인으로 복구하거나 (b) **실패 지점에서 대체 수단을 즉시 제시**하는가? → `minor`
3. 사람의 판단이 필요하거나 실패 없이 **조용히 동작만 바뀌는가**? → `major`

## 등급 정의

| bump | 정의 | 예 |
|---|---|---|
| `patch` | 공개 인터페이스가 그대로입니다. 내부 구현, 문서, 스킬 본문, `dist` 재생성. | 절차 문구 개선, `install.sh` 버그 수정, `README` 재구성, `dist` 레이아웃 변경 |
| `minor` | 새 기능, 또는 **유도된 파괴(guided break)**. | 새 스킬·새 target 추가, 제거된 옵션이 대체 명령을 안내하며 실패, 스킬 디렉토리 rename을 `jig-update`가 자동 이관 |
| `major` | **사람의 결정**이 필요하거나, **조용한 동작 변경**. | 브랜치 모델 변경, branch protection 정책 변경, 사용자 파일·라벨 삭제, 같은 명령이 에러 없이 다른 결과를 내는 변경 |

핵심 완화는 **고칠 수 있는 파괴는 `minor`** 라는 점입니다. 그 대가로 강경 규칙 하나가 붙습니다.

> **조용한 동작 변경은 무조건 `major`입니다.**

실패가 시끄러우면 사용자 비용은 오류 메시지 한 줄입니다. 조용하면 디버깅 세션입니다. 이 가드가 있어야 나머지를 느슨하게 풀어도 정직합니다.

## 공개 인터페이스

무엇이 깨지면 파괴인지 매번 재론하지 않도록 목록을 고정합니다.

**공개 — 여기가 깨지면 최소 `minor`**

1. curl 원라이너와 설치 후 GitHub 프로필 계약: `--target`, `--scope`, 선택 옵션 `--github-profile`/`--github-account`, `JIG_GITHUB_PROFILE`, `jig.githubProfile`
2. 스킬 호출 이름: `/jig:github-release`, `jig-github-release`
3. 플러그인·마켓플레이스 이름: `jig@jig`, `0x0w1/spai`
4. managed block marker 문자열: `<!-- jig:start ... -->`, `<!-- jig:end ... -->`
5. 저장소 모델: 브랜치 이름, 병합 흐름, 보호 정책

**내부 — 깨져도 `patch`**

`dist/` 레이아웃, `scripts/*`, 스킬 본문 내용, 버전 스탬프의 `version` 외 필드, 로그 문구, `README`·`docs` 구조

## 기계 판독 마이그레이션

`### Migration` 섹션은 자유 서술이 아니라 두 종류의 marker 블록으로 씁니다. 사람이 읽는 문단이 아니라 `jig-update`가 실행하는 입력이기 때문입니다.

```md
### Migration

<!-- jig:start migration-auto -->
- `rm -f .github/workflows/drafter.yaml`
- `.agents/skills/github-sync/`가 있으면 `.agents/skills/jig-github-sync/`로 이동
<!-- jig:end migration-auto -->

<!-- jig:start migration-manual -->
- `develop`의 required status check 유지 여부를 결정하세요. jig는 더 이상 설정하지 않습니다.
<!-- jig:end migration-manual -->
```

| 블록 | 뜻 | 처리 |
|---|---|---|
| `migration-auto` | 에이전트가 무인으로 끝낼 수 있는 기계적 조치 | `jig-update`가 실행 |
| `migration-manual` | 사람의 판단이 필요한 조치 | `jig-update`가 제시하고 **승인 전까지 실행하지 않음** |

`auto` 항목은 **멱등**이어야 하고 하나의 명령이거나 모호하지 않은 파일 조작이어야 합니다. 대상이 이미 없으면 통과로 처리됩니다. 판단·선택·되돌릴 수 없는 조치는 전부 `manual`입니다.

**marker는 줄 전체일 때만 marker입니다** (`^<!-- jig:(start|end) migration-(auto|manual) -->$`). 릴리즈 노트는 이 marker 이름을 본문에서 자주 언급하므로 백틱 안이나 문장 중간에 나온 것은 그냥 텍스트입니다. 부분 문자열로 세면 본문 언급까지 블록으로 오인합니다. 열린 블록에 짝이 되는 end marker가 없으면 결함으로 보고하고 아무것도 실행하지 않습니다.

### 버전이 노트에서 도출됩니다

두 블록의 유무가 bump를 강제합니다. 등급은 취향이 아니라 노트에서 나오는 파생값입니다.

| 노트에 있는 것 | 강제되는 bump |
|---|---|
| Migration 섹션 없음 | `patch` 또는 `minor` (판정 순서로 결정) |
| `migration-auto`만 | 최소 `minor` |
| `migration-manual`이 하나라도 | **`major`** |

`github-release`는 노트를 쓴 뒤 이 검사를 수행하고 판정과 요청 bump가 어긋나면 멈추고 보고합니다.

## 1.0 이전

현재 `0.x`이므로 `major` 판정이 나와도 `v0.(Y+1).0`으로 올림합니다. 등급 판정 자체는 1.0 이후와 동일하게 수행하고 릴리즈 보고에 판정 결과를 남깁니다. 규칙이 구속력을 갖기 전에 미리 굽는 것이 목적입니다.

자리 올림과 무관하게 `migration-manual` 블록은 그대로 실어야 합니다. 자리만 낮아지는 것이지 사용자가 할 일이 사라지는 게 아닙니다.

## 적용 예

| 릴리즈 | 판정 | 근거 |
|---|---|---|
| `v0.2.0` 플러그인 전환 | `major` | 호출 이름이 `/github-release` → `/jig:github-release`로 바뀌었는데 구버전이 복사한 파일이 조용히 남아 동작이 갈림. 실패하지 않는 변경 |
| `v0.2.1` target 분리 | `minor` | 공개 1번을 깨지만 `--target all` 실행 시 대체 명령을 알려주며 중단 = 유도된 파괴 |

두 릴리즈 모두 당시 규칙으로는 다른 등급으로 나갔습니다. 이 표는 새 규칙이 어떻게 판정하는지 보여주는 기준 예시입니다.

## 관련 문서

- [설치 가이드](installation.ko.md)
- [GitHub Repository Settings](github-repository-settings.ko.md)
