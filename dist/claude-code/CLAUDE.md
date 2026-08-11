Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI ships these repository workflow skills through the spai Claude Code plugin. Plugin skills are namespaced, so they never collide with skills you wrote yourself.

- `/spai:github-sync`: repository setup and synchronization; not for creating releases.
- `/spai:github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `/spai:develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `/spai:spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `/spai:spai-doctor`: diagnose the installed SPAI state (version, protection, legacy); read-only.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
