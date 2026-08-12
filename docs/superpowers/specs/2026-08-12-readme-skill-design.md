# `readme` 스킬 설계

> 상태: 승인된 설계 (2026-08-12)
> 다음 릴리즈 영향: 새 capability → `minor` (v0.4.0 예상)

## 목적

설치된 사이드 프로젝트에서 그 프로젝트의 `README.md`를 작성하거나 갱신하는 SPAI 배포 절차 스킬. 기존 5종과 동일하게 `skills/`를 원본으로 모든 CLI(Claude Code, Codex, Antigravity)로 배포한다.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 배포 범위 | SPAI 배포 스킬 (manifest·dist 포함, 전 CLI 배포) |
| 동작 범위 | 생성 + 갱신 겸용, 하나의 절차에서 분기 |
| 구조 기준 | 필수 섹션 고정 + 프로젝트 타입별 가변 섹션 |
| 언어 | 기존 README 언어 유지, 신규는 한국어 기본, 사용자 명시 우선 |
| 스킬 이름 | `readme` (호출: `/spai:readme`, `spai-readme`) |
| 접근 방식 | 단일 스킬, 진단 후 분기 (`spai-doctor`/`github-sync`의 진단→수렴 패턴) |

## 스킬 절차 (`skills/readme/SKILL.md`)

1. **저장소 스캔** — 매니페스트 파일(`pyproject.toml`, `package.json` 등), 진입점, 스크립트, 기존 문서를 확인하고 프로젝트 타입을 판정한다: CLI 도구 / 라이브러리 / 서비스·앱 / 기타.
2. **분기**
   - README 없음 → **생성 경로**: 타입별 섹션 구성으로 초안을 작성한다.
   - README 있음 → **갱신 경로**: README의 주장(명령, 옵션, 구조, 링크)을 코드와 대조해 드리프트 목록을 만들어 보고한 뒤 수정한다.
3. **정확성 규칙** — 설치·실행 명령은 저장소에서 실제 검증된 것만 쓴다. 파일 링크는 실존을 확인한다. 없는 기능·배지를 서술하지 않는다. 확인할 수 없는 항목은 쓰지 않고 보고한다.
4. **언어 규칙** — 기존 README의 언어를 유지한다. 신규 작성은 한국어 기본, 기술 용어는 백틱. 사용자가 언어를 명시하면 그것이 우선한다.
5. **병합** — `develop-task-flow`(또는 설치본의 `spai-develop-task-flow`)가 있으면 그 절차를 따른다: `chore/<slug>` 브랜치 → squash merge(`docs:` prefix 커밋) → `develop` push. 없으면 일반 커밋을 제안한다.

### 섹션 구성

- **공통 필수**: 제목 + 한 줄 소개 / 프로젝트 소개 / 설치 / 사용법
- **타입별 추가**: CLI 도구 → 명령·옵션 표, 라이브러리 → API 요약·예제 코드, 서비스·앱 → 실행 방법(dev/prod)·환경 변수
- **선택**: 문서 링크, 라이선스

## 배포 통합

- `manifest.tsv`에 `readme	solo-cli	yes` 행 추가 (`dist/manifest.tsv`는 빌드 산출물)
- `scripts/build-dist.sh`의 `skill_summary()`에 `readme` case 추가
- `sh scripts/build-dist.sh`로 재생성: `dist/codex`·`dist/antigravity`에 `spai-readme`, Claude Code 플러그인에 `readme`
- 저장소 내 사본 동기화: `.agents/skills/spai-readme/`, `.claude/skills/readme/`
- installer는 manifest 기반이므로 코드 변경 없음 (구현 시 확인)

## 검증

- `sh scripts/validate-dist.sh` 통과
- 드라이런: 이 저장소의 기존 README로 갱신 경로 절차를 점검

## 범위 밖

- README 이외의 문서(위키, docs/ 구조) 생성
- 배지·CI 상태 표시 자동화
- 다국어 README 병행 유지
