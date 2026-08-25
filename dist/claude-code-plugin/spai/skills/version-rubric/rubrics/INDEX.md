# Version Rubric Catalog Index

Ready-made `.spai/versioning.md` drafts, one per project type. `rubric-scan` scans the repository and reads only this file to pick candidate types; `version-rubric` then writes the chosen type's body as the draft. A person can also pick straight from the table.

## Directory

```text
rubrics/
├── INDEX.md         # this file: the type list and the detection signals
├── _template.md     # skeleton for adding a type
├── common.md        # SemVer principles that hold across every type
└── <type>.md        # one draft per type, all on one level
```

Type drafts live on one level with no grouping directories. The `Consumer` column below does the grouping, because one project often serves several kinds of consumer at once. A directory split pushes such a project into one side, and it moves the file path whenever the project's character changes.

Principles that hold regardless of type are in [Common SemVer Principles](common.md). Grade the ambiguous cases a type draft does not cover from there.

## Which Axis This Catalog Grades On

Every draft here grades on the **SemVer consumer-compatibility axis**. The only question is what existing consumers must change between the previous release and this one.

The rubric `version-rubric` offers by default uses a different axis. That one is the **human-intervention axis**: adding, removing, or replacing capability is all `minor`, and only a change that forces a human to step in becomes `major`. It exists so the number keeps carrying information in a project whose generations turn over quickly.

The two axes grade the same change differently.

| Change | Catalog (SemVer compatibility) | SPAI default (human intervention) |
|---|---|---|
| A feature or endpoint removed | `major` | `minor` |
| Generation replaced, contract intact | `patch` | `minor` |
| Silent behavior change | `major` | `major` |

**Use one or the other.** Adopting a catalog draft makes that file the project's whole rubric; do not fold questions from the default into it. A project with clear outside consumers — installs, callers, readers — fits the catalog. A project whose only consumer is itself, or whose consumers are not settled yet, fits the default.

## What a Type Actually Changes

The `## Decision Order` in all 17 drafts is effectively the same three questions. A type really changes only three things.

| Section | What differs by type |
|---|---|
| `## Public Interface` | What reaches the consumer. This is the substance of the catalog |
| `## Hard Rules` | How this type **breaks quietly, without raising an error** |
| `## Pre-Release Checks` | How to catch that break before releasing |

Write a new type with those three in mind. `## Decision Order` and `## Grade Definitions` only need the three questions from [Common SemVer Principles](common.md) restated with this type's nouns.

## How to Choose

1. Write down what **reaches someone else** when this repository releases: an endpoint that is called, a package that is installed, a screen that opens, a document that is read, an asset that is reused, a configuration that is applied.
2. Write down what that person must fix if it breaks. That is this project's public interface, and matching it against the `Consumer` column gives the type.
3. If two or more match, do not pick one — [merge them](#when-several-types-match).

## Types

| Type | Consumer | Strong signals | Weak signals |
|---|---|---|---|
| [api-server](api-server.md) | API callers, integrating services | `openapi.*`, `swagger.*`, `urls.py`, `routes/`, `controllers/`, dependencies on `fastapi`, `django`, `express`, `nestjs`, `spring-boot`, `gin` | `migrations/`, `docker-compose.yml`, `.bru` or `.http` collections |
| [background-worker](background-worker.md) | Message producers, downstream systems | `worker.*`, `consumer.*`, `tasks.py`, dependencies on `celery`, `sidekiq`, `bull`, `kafka`, `rabbitmq`, `sqs`, schedule definitions | a `docker-compose.yml` that starts a broker |
| [data-pipeline](data-pipeline.md) | Downstream tables, reports, model users | `dags/`, `dbt_project.yml`, dependencies on `airflow`, `dagster`, `prefect`, `models/*.sql` | `data/`, `*.parquet`, scheduled run workflows |
| [web-client](web-client.md) | Browser users, bookmarks and links | `index.html` with `vite.config.*`, `next.config.*`, or `webpack.config.*`, dependencies on `react`, `vue`, `svelte`, `angular`, `src/pages/`, `src/app/` | `tailwind.config.*`, `playwright.config.*`, `cypress/` |
| [mobile-app](mobile-app.md) | Store-installed users, on-device data | `pubspec.yaml`, `*.xcodeproj`, `Info.plist`, `AndroidManifest.xml`, `android/app/build.gradle`, `app.json` with expo | `fastlane/`, store metadata directories |
| [desktop-app](desktop-app.md) | Installed users, local files and settings | `src-tauri/`, `tauri.conf.json`, a dependency on `electron`, `electron-builder.*`, WPF or Qt project files | auto-update configuration (`latest.yml`, `updater`) |
| [library-sdk](library-sdk.md) | Code that imports this package | `exports`, `types`, `files` in `package.json`, publishing metadata in `pyproject.toml`, `setup.py`, `Cargo.toml [lib]`, a `go.mod` with no executable entrypoint | `CHANGELOG.md`, `docs/api/`, release automation config |
| [cli-tool](cli-tool.md) | Terminal users, scripts that call this command | `[project.scripts]`, `bin` in `package.json`, `cmd/` with cobra, `src/cli.*`, a distribution `install.sh` | shell completion, `--help` snapshot tests |
| [agent-skill-pack](agent-skill-pack.md) | Repositories that installed the skills, agent sessions | many `SKILL.md` files, `.claude/skills/`, `.agents/skills/`, `.claude-plugin/`, `AGENTS.md`, `prompts/` | `evals/`, `mcp.json` |
| [infrastructure](infrastructure.md) | Projects that reference the module, operators | `*.tf`, `terragrunt.hcl`, `Chart.yaml`, `kustomization.yaml`, `ansible/`, `serverless.yml`, `Pulumi.yaml` | `.github/workflows/deploy*`, state backend configuration |
| [config-collection](config-collection.md) | The machines and tools this configuration is applied to | many top-level dotfiles (`.zshrc`, `.vimrc`), `.config/`, `Brewfile`, `chezmoi` or `stow` configuration, a collection of tool `settings.json` | an `install.sh` that creates symlinks |
| [monorepo](monorepo.md) | Every package's consumers | `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `go.work`, `Cargo.toml [workspace]`, `[tool.uv.workspace]` | `apps/` and `packages/` present together |
| [document-archive](document-archive.md) | People who look documents up, documents that link here | most tracked files are `.md`, `.docx`, or `.pdf`, no dependency manifest and no executable entrypoint, classification directories (`manuals/`, `policies/`, `meetings/`) | `templates/`, filenames on a date convention |
| [content-site](content-site.md) | Readers of published pages, search engines, subscribers | `hugo.toml` with `content/`, `_config.yml` with `_posts/`, `docusaurus.config.*`, `mkdocs.yml`, `astro.config.*` with `src/content/` | `static/`, `assets/images/`, RSS configuration |
| [course-material](course-material.md) | Learners, and whoever teaches from this material | `week-*`, `lesson-*`, or `chapter-*` directories, `syllabus.md`, `exercises/` with `solutions/`, teaching `*.ipynb` | `slides/`, many lecture images |
| [design-assets](design-assets.md) | Screens, print pieces, and other repositories that use the assets | `*.fig`, `*.sketch`, `*.psd`, `*.ai`, many `*.svg`, `icons/`, `brand/`, `tokens.json` | `exports/`, many `*.png` |
| [dataset](dataset.md) | Analyses, reports, and automation that read the data | many `*.csv`, `*.tsv`, `*.parquet`, or `*.xlsx`, `data/raw` with `data/processed`, `schema.json`, `datapackage.json` | small conversion `scripts/`, a `README` with column definitions |

The table is ordered so types with similar consumers sit together: called and executed things at the top, installed and imported things in the middle, read and reused things at the bottom. Whether a developer built the project has no bearing on the grade — a documents-only repository maintained by a developer is still `document-archive`, and a repository maintained by a designer that ships an API is still `api-server`.

## Scan Scoring

1. A strong signal is worth 2 points and a weak signal 1 point. Within one type, the same signal counts once even when it matches several files.
2. A type below 3 points is not reported as a candidate. One incidental file must not promote a type. That also means a single strong signal is not enough on its own — a repository with many documents is not the same as a document repository.
3. Report at most 3 candidates, highest score first, and give **the actual paths that produced the score** for each. Never recommend without evidence paths.
4. If every type scores below 3, pick no type and recommend the default rubric (human-intervention axis) from `version-rubric`.
5. If `monorepo` matches, run the scan once more over the sub-packages and report which types live inside. `monorepo` wraps other types rather than replacing them.

## When Several Types Match

Several consumers mean several types. Do not pick one; do this instead.

- Take the primary type's body as the draft and merge the other types' `## Public Interface` items underneath it.
- When one change grades differently per interface, use **the highest grade**. Shipping a server and a web client together does not let UI compatibility lower the grade while external API consumers exist.
- If artifacts are versioned separately, read [monorepo](monorepo.md) for the propagation strategy.

## Adding a Type

1. Copy [`_template.md`](_template.md) to `<id>.md` on this same level. Do not create a subdirectory.
2. Add a row to the table above, next to the rows with a similar consumer. **A file missing from the table is invisible to the scan.**
3. A strong signal must be a path that appears only in that type. Files that exist everywhere, such as `README.md` or `.gitignore`, are not signals.
4. Fill both required sections (`## Decision Order`, `## Grade Definitions`). The rest are optional.
5. The file must be copyable to `.spai/versioning.md` as-is. Keep catalog commentary and frontmatter out of the body.
