# README Profile

> Basis: 직접 작성 (기존 README 구조와 저장소 규칙에서 추출), 2026-09-01

이 파일이 이 저장소 README 작성의 규범 원본이다. `readme` 스킬이 읽는다. 결정만 담고 검사 항목은 두지 않는다 — README 품질은 판정이지 기계 검사가 아니고, 기계로 되는 것은 `scripts/validate-dist.sh`가 이미 본다.

## Languages

정본은 `README.md`(영문), 미러는 `README.ko.md`(국문)다. 한쪽을 고치면 같은 task에서 다른 쪽도 고친다. 국문 산문은 `README.md`에 들어가지 않는다.

`docs/`도 같은 구조를 따른다: `docs/en/`이 표현 기준본, `docs/ko/`가 같은 상대 경로·제목 계층을 갖는 미러. rubric 카탈로그는 스킬 payload로 나가므로 영문만 유지한다.

## Sections

제목 → 로고 → 배지 → 한 줄 소개 → 언어 링크 → 이동 링크 줄 → What This Is → Quick Start → Skills → Documentation → Updating → License.

이동 링크 줄은 유지한다. 섹션이 여섯이라 돌아온 독자가 위에서 목적지로 바로 간다.

Quick Start는 번호 붙은 세 단계(설치 → 저장소 바인딩 → 검증)로 두고, CLI별로 블록을 나누지 않는다. Codex와 Antigravity는 `--target` 값만 다르므로 한 블록에서 인자로 구분한다.

## Detail Docs

README에 두지 않고 상세 문서로 보내는 것:

- installer 옵션 전체 표, 설치 위치, 스킬 이름 규칙, 제거 절차 → `docs/en/installation.md`
- 스킬별 워크플로, 안전 경계, 다이어그램 → `docs/en/skills/`
- 등급 판정 해설과 파일 계약 → `docs/en/version-rubric.md`, `docs/en/versioning.md`
- branch protection 판정 절차 → `docs/en/github-repository-settings.md`
- 방향 후보와 설계 기록 → `docs/en/roadmap.md`. 문서 홈에서만 링크하고 README에서는 링크하지 않는다. 설치 전에 읽는 내용이 아니다

`dist` 재생성과 검증 명령은 기여자용이므로 README 본문에 펼치지 않는다.

## Conventions

스킬 표는 유지한다. 첫 열이 사람이 복사하는 식별자이므로 설명 셀을 한 절로 짧게 유지한다. GitHub이 내용 길이로 열 폭을 잡아서, 설명이 길어지면 `develop-task-flow` 같은 이름이 단어 중간에서 줄바꿈된다.

가치 주장은 저장소가 보일 수 있는 것만 쓴다. 짧은 규칙 파일로 재현 가능한 관습은 강점으로 주장하지 않고, 값이 나는 적용 전제를 함께 적는다.

소개 항목은 근거가 강한 순으로 정렬하고, 주변 문단의 나열 순서도 같게 맞춘다.

공개 에셋은 `resources/readme/`에서만 참조한다.
