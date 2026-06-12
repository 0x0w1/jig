# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs reusable project skills for repository release and development workflows.

Available Claude Code skills:

- `/github-sync`: repository setup and synchronization; not for creating releases.
- `/github-release`: release/vX.Y.Z execution from develop to main.
- `/develop-task-flow`: normal development tasks from develop through a PR back to develop.
- `/knowledges-quick-ingest`: send small project knowledge into a configured LLM + Obsidian + Graphify knowledges vault.

Additional knowledges rules and guardrails are installed under `.claude/rules/` and `.claude/guardrails/`.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
