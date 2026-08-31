jig - repository procedures for AI agent CLIs

<!-- jig:start github-release-setup -->
<!-- jig:version dev -->

jig installs these repository workflow skills under .agents/skills. Every jig skill name carries the jig- prefix so it stays out of the way of skills you wrote yourself.

- `jig-github-sync`: repository setup and synchronization; not for creating releases.
- `jig-github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `jig-develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `jig-hotfix-flow`: jig procedure.
- `jig-setup`: install jig for a repository and select its GitHub CLI profile without changing the global active account.
- `jig-update`: update the installed jig skills to the latest jig release and converge repository settings.
- `jig-doctor`: diagnose every installed jig target and scope plus repository profile, version, protection, and legacy state; read-only.
- `jig-repo-hygiene`: jig procedure.
- `jig-readme`: write or update the project README from the repository state; drafts one when missing, fixes drift when present.
- `jig-version-rubric`: decide and maintain how this project grades patch, minor, and major in .jig/versioning.md; ships the project-type rubric catalog.
- `jig-rubric-scan`: scan the repository to classify its project type and recommend a version rubric from the catalog; read-only.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- jig:end github-release-setup -->
