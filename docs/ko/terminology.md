# jig 용어

[English](../en/terminology.md) · [문서 홈](index.md)

구현하거나 배포할 범위가 달라질 수 있을 때는 다음 용어를 사용합니다.

## jig 제품

사용자에게 전달되는 동작과 payload입니다. 설치되는 skill, installer·update 동작, 생성된 `dist/`, plugin hook, 설치된 저장소에 제품이 만드는 상태를 포함합니다.

**jig 제품 변경**은 Claude Code, Codex, Antigravity, release, migration, 기존 설치본에 영향을 줄 수 있습니다. 일반적으로 source skill 복사본과 distribution을 함께 동기화해야 합니다.

## jig 소스 저장소

jig 제품을 개발하는 현재 저장소입니다. repo-local agent 지침, validation, project plan, 문서 유지 관리, contributor tooling은 제품 payload에 의도적으로 추가하지 않는 한 이 범위에만 속합니다.

**jig 소스 저장소 규칙**은 jig 자체를 만드는 작업에 적용되며 jig-managed project에서 지원하는 제품 기능이 되지는 않습니다.

## jig 적용 프로젝트

jig가 설치되어 사용되는 외부 저장소입니다. clone-local hook, `.jig/` 파일, local Git config, branch 상태, GitHub 설정은 jig 적용 프로젝트의 상태입니다.

## 명명 규칙

구현 범위가 달라질 수 있을 때는 “이 프로젝트”나 “현재 프로젝트”를 피하고 범위를 명시합니다.

- **jig 제품 기능**: 사용자에게 배포
- **jig 소스 저장소 규칙**: jig를 개발할 때만 사용
- **jig 적용 프로젝트 상태**: 설치된 저장소에서 생성하거나 진단
