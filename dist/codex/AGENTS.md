Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI installs these repository workflow skills under .agents/skills. Every SPAI skill name carries the spai- prefix so it stays out of the way of skills you wrote yourself.

- `spai-github-sync`: repository setup and synchronization; not for creating releases.
- `spai-github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `spai-develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `spai-project-setup`: install SPAI for a repository and select its GitHub CLI profile without changing the global active account.
- `spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `spai-doctor`: diagnose the installed SPAI state (profile, version, protection, legacy); read-only.
- `spai-readme`: write or update the project README from the repository state; drafts one when missing, fixes drift when present.
- `spai-version-rubric`: decide and maintain how this project grades patch, minor, and major in .spai/versioning.md.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
