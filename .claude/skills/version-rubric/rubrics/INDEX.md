# 버전 기준 카탈로그 색인

프로젝트 유형별 `.spai/versioning.md` 초안 모음입니다. `rubric-scan`은 저장소를 스캔한 뒤 이 파일 하나만 읽어 후보 유형을 고르고, `version-rubric`은 사용자가 고른 유형의 본문을 초안으로 씁니다. 사람이 표에서 직접 골라도 됩니다.

## 디렉토리

```text
rubrics/
├── INDEX.md            # 이 파일. 유형 목록과 탐지 신호
├── _template.md        # 새 유형을 추가할 때 쓰는 골격
├── common.md           # 유형과 무관한 공통 SemVer 원칙
├── developer/          # 코드 소비자와의 계약으로 판정하는 유형
└── non-developer/      # 산출물·발행물 계약으로 판정하는 유형
```

유형과 무관한 공통 원칙은 [공통 SemVer 원칙](common.md)에 있습니다. 유형 문서가 다루지 않는 애매한 사례는 여기서 판정합니다.

`developer/`와 `non-developer/`는 난이도가 아니라 **공개 인터페이스의 종류**로 갈립니다. `developer/`는 호출·import·배포 계약이 소비자에게 닿고, `non-developer/`는 문서·자산·데이터·발행물 자체가 소비자에게 닿습니다. 비개발자가 관리하는 저장소라도 API를 배포하면 `developer/`를 씁니다.

## developer 유형

| id | 소비자 | 강한 신호 | 약한 신호 |
|---|---|---|---|
| [api-server](developer/api-server.md) | API 호출자, 연동 서비스 | `openapi.*`, `swagger.*`, `urls.py`, `routes/`, `controllers/`, 의존성에 `fastapi`·`django`·`express`·`nestjs`·`spring-boot`·`gin` | `migrations/`, `docker-compose.yml`, `.bru`·`.http` 컬렉션 |
| [web-client](developer/web-client.md) | 브라우저 사용자, 북마크·링크 | `index.html` + `vite.config.*`·`next.config.*`·`webpack.config.*`, 의존성에 `react`·`vue`·`svelte`·`angular`, `src/pages/`·`src/app/` | `tailwind.config.*`, `playwright.config.*`, `cypress/` |
| [mobile-app](developer/mobile-app.md) | 스토어 설치 사용자, 기기 로컬 데이터 | `pubspec.yaml`, `*.xcodeproj`, `Info.plist`, `AndroidManifest.xml`, `android/app/build.gradle`, `app.json` + expo | `fastlane/`, 스토어 메타데이터 디렉토리 |
| [desktop-app](developer/desktop-app.md) | 설치 사용자, 로컬 파일·설정 | `src-tauri/`, `tauri.conf.json`, 의존성에 `electron`, `electron-builder.*`, WPF·Qt 프로젝트 파일 | 자동 업데이트 설정(`latest.yml`, `updater`) |
| [library-sdk](developer/library-sdk.md) | 이 패키지를 import 하는 코드 | `package.json`의 `exports`·`types`·`files`, `pyproject.toml`의 배포 메타데이터, `setup.py`, `Cargo.toml [lib]`, 실행 진입점 없는 `go.mod` | `CHANGELOG.md`, `docs/api/`, 릴리즈 자동화 설정 |
| [cli-tool](developer/cli-tool.md) | 터미널 사용자, 이 명령을 호출하는 스크립트 | `[project.scripts]`, `package.json`의 `bin`, `cmd/` + cobra, `src/cli.*`, 배포용 `install.sh` | shell completion, `--help` 스냅샷 테스트 |
| [background-worker](developer/background-worker.md) | 메시지 생산자, 하류 시스템 | `worker.*`, `consumer.*`, `tasks.py`, 의존성에 `celery`·`sidekiq`·`bull`·`kafka`·`rabbitmq`·`sqs`, 스케줄 정의 | broker를 띄우는 `docker-compose.yml` |
| [infrastructure](developer/infrastructure.md) | 이 module을 참조하는 프로젝트, 운영자 | `*.tf`, `terragrunt.hcl`, `Chart.yaml`, `kustomization.yaml`, `ansible/`, `serverless.yml`, `Pulumi.yaml` | `.github/workflows/deploy*`, state 백엔드 설정 |
| [monorepo](developer/monorepo.md) | 패키지별 소비자 전부 | `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `go.work`, `Cargo.toml [workspace]`, `[tool.uv.workspace]` | `apps/`와 `packages/`가 함께 존재 |
| [data-pipeline](developer/data-pipeline.md) | 하류 테이블·리포트·모델 사용자 | `dags/`, `dbt_project.yml`, 의존성에 `airflow`·`dagster`·`prefect`, `models/*.sql` | `data/`, `*.parquet`, 스케줄 실행 워크플로 |
| [agent-skill-pack](developer/agent-skill-pack.md) | 이 스킬을 설치한 저장소와 에이전트 세션 | `SKILL.md` 다수, `.claude/skills/`, `.agents/skills/`, `.claude-plugin/`, `AGENTS.md`, `prompts/` | `evals/`, `mcp.json` |

## non-developer 유형

| id | 소비자 | 강한 신호 | 약한 신호 |
|---|---|---|---|
| [document-archive](non-developer/document-archive.md) | 문서를 찾아 읽는 사람, 링크를 건 문서 | 추적 파일의 다수가 `.md`·`.docx`·`.pdf`, 의존성 manifest와 실행 진입점이 모두 없음, 분류 디렉토리(`manuals/`, `policies/`, `meetings/`) | `templates/`, 날짜 규칙이 붙은 파일명 |
| [content-site](non-developer/content-site.md) | 발행된 페이지 독자, 검색엔진, 구독자 | `hugo.toml` + `content/`, `_config.yml` + `_posts/`, `docusaurus.config.*`, `mkdocs.yml`, `astro.config.*` + `src/content/` | `static/`, `assets/images/`, RSS 설정 |
| [design-assets](non-developer/design-assets.md) | 자산을 가져다 쓰는 화면·인쇄물·다른 저장소 | `*.fig`, `*.sketch`, `*.psd`, `*.ai`, 다량의 `*.svg`, `icons/`, `brand/`, `tokens.json` | `exports/`, 다량의 `*.png` |
| [dataset](non-developer/dataset.md) | 데이터를 읽는 분석·리포트·자동화 | 다량의 `*.csv`·`*.tsv`·`*.parquet`·`*.xlsx`, `data/raw`와 `data/processed`, `schema.json`, `datapackage.json` | 소규모 변환 `scripts/`, 컬럼 정의가 있는 `README` |
| [config-collection](non-developer/config-collection.md) | 이 설정을 적용하는 기기와 도구 | 최상위 dotfile 다수(`.zshrc`, `.vimrc`), `.config/`, `Brewfile`, `chezmoi`·`stow` 설정, 도구 `settings.json` 모음 | 심볼릭 링크를 거는 `install.sh` |
| [course-material](non-developer/course-material.md) | 수강자, 이 자료로 가르치는 사람 | `week-*`·`lesson-*`·`chapter-*` 디렉토리, `syllabus.md`, `exercises/`와 `solutions/`, 강의용 `*.ipynb` | `slides/`, 다량의 강의 이미지 |

## 스캔 점수 규칙

1. 강한 신호 1건은 2점, 약한 신호 1건은 1점입니다. 같은 유형 안에서 같은 신호가 여러 파일에 걸려도 1건으로 셉니다.
2. 3점 미만인 유형은 후보로 보고하지 않습니다. 파일 하나가 우연히 걸린 것을 유형으로 승격시키지 않기 위해서입니다. 강한 신호 하나만으로 유형이 되지 않는다는 뜻이기도 합니다 — 문서가 많은 저장소와 문서 저장소는 다릅니다.
3. 후보는 점수 순으로 최대 3개까지 보고하고, 각 후보마다 **점수를 만든 실제 경로**를 함께 적습니다. 근거 경로 없는 추천은 하지 않습니다.
4. 모든 유형이 3점 미만이면 유형을 고르지 않고 `version-rubric`의 기본 기준(사람 개입 축)을 권합니다.
5. `monorepo`가 걸리면 하위 패키지에 대해 스캔을 한 번 더 돌려 안에 어떤 유형이 들었는지 함께 보고합니다. `monorepo`는 다른 유형을 대체하지 않고 감쌉니다.

## 유형이 여러 개 잡히면

소비자가 여럿이면 유형도 여럿입니다. 하나를 고르지 말고 다음을 따릅니다.

- 주 유형의 본문을 초안으로 삼고, 다른 유형의 `## 공개 인터페이스`(비개발자 유형은 `## 소비자와 약속한 것`) 항목을 그 아래로 합칩니다.
- 같은 변경에 등급이 갈리면 **가장 높은 등급**을 씁니다. 서버와 웹을 함께 배포해도 외부 API 소비자가 있으면 UI 호환성만으로 등급을 낮출 수 없습니다.
- 산출물별로 버전을 따로 매기면 [monorepo](developer/monorepo.md)의 전파 전략을 함께 읽습니다.

## 새 유형 추가

1. [`_template.md`](_template.md)를 복사해 `developer/` 또는 `non-developer/` 아래에 `<id>.md`로 만듭니다.
2. 위 표에 행을 추가합니다. **표에 없는 파일은 스캔이 찾지 못합니다.**
3. 강한 신호는 그 유형에서만 나오는 경로여야 합니다. `README.md`나 `.gitignore`처럼 어디에나 있는 파일은 신호가 아닙니다.
4. 필수 섹션 2개(`## 판정 순서`, `## 등급 정의`)를 반드시 채웁니다. 나머지는 선택입니다.
5. 파일을 그대로 `.spai/versioning.md`로 복사할 수 있어야 합니다. 카탈로그 설명이나 frontmatter를 본문에 넣지 않습니다.
