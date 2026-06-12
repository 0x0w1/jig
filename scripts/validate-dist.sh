#!/usr/bin/env sh
set -eu

SKILLS="github-sync github-release develop-task-flow knowledges-quick-ingest"
RULES="knowledges-raw-contract"
GUARDRAILS="knowledges-ingest"

fail() {
  echo "validate-dist: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_text() {
  file="$1"
  text="$2"
  grep -F "$text" "$file" >/dev/null 2>&1 || fail "missing text in $file: $text"
}

skill_title() {
  case "$1" in
    github-sync) printf '%s\n' "# GitHub Sync" ;;
    github-release) printf '%s\n' "# GitHub Release" ;;
    develop-task-flow) printf '%s\n' "# Develop Task Flow" ;;
    knowledges-quick-ingest) printf '%s\n' "# Knowledges Quick Ingest" ;;
    *) fail "unknown skill: $1" ;;
  esac
}

require_file dist/github/drafter-config.yaml
require_file dist/github/workflows/drafter.yaml
require_file dist/github/PULL_REQUEST_TEMPLATE.md
require_text dist/github/drafter-config.yaml "### Summary"
require_text dist/github/drafter-config.yaml '### $TITLE'
require_text dist/github/drafter-config.yaml "type: \"version-resolver\""
require_text dist/github/workflows/drafter.yaml "release-drafter/release-drafter@v7"
require_text dist/github/workflows/drafter.yaml "Append summary release notes"
require_text dist/github/PULL_REQUEST_TEMPLATE.md "## Summary"
require_text dist/github/PULL_REQUEST_TEMPLATE.md "## Details"
require_text dist/github/PULL_REQUEST_TEMPLATE.md "## Tests"

require_file dist/claude-code/CLAUDE.md
require_text dist/claude-code/CLAUDE.md "spai:start github-release-setup"
require_text dist/claude-code/CLAUDE.md "spai:end github-release-setup"

require_file dist/codex/AGENTS.md
require_text dist/codex/AGENTS.md "spai:start github-release-setup"
require_text dist/codex/AGENTS.md "spai:end github-release-setup"

require_file dist/gemini-cli/GEMINI.md
require_text dist/gemini-cli/GEMINI.md "spai:start github-release-setup"
require_text dist/gemini-cli/GEMINI.md "spai:end github-release-setup"

require_file dist/opencode/AGENTS.md
require_text dist/opencode/AGENTS.md "spai:start github-release-setup"
require_text dist/opencode/AGENTS.md "spai:end github-release-setup"

for skill in $SKILLS; do
  title=$(skill_title "$skill")
  require_file "dist/claude-code/.claude/skills/$skill/SKILL.md"
  require_file "dist/codex/.agents/skills/$skill/SKILL.md"
  require_file "dist/cursor/.cursor/rules/$skill.mdc"
  require_text "dist/claude-code/.claude/skills/$skill/SKILL.md" "$title"
  require_text "dist/codex/.agents/skills/$skill/SKILL.md" "$title"
  require_text "dist/cursor/.cursor/rules/$skill.mdc" "$title"
  require_text dist/codex/AGENTS.md "$skill"
  require_text dist/gemini-cli/GEMINI.md "$skill"
  require_text dist/opencode/AGENTS.md "$skill"
done

for rule in $RULES; do
  require_file "rules/$rule.md"
  require_file "dist/claude-code/.claude/rules/$rule.md"
  require_file "dist/codex/.agents/rules/$rule.md"
  require_file "dist/cursor/.cursor/rules/$rule.mdc"
  require_text "dist/claude-code/.claude/rules/$rule.md" "Knowledges Raw Contract"
  require_text "dist/codex/.agents/rules/$rule.md" "Knowledges Raw Contract"
  require_text "dist/cursor/.cursor/rules/$rule.mdc" "Knowledges Raw Contract"
  require_text dist/codex/AGENTS.md "$rule"
  require_text dist/gemini-cli/GEMINI.md "$rule"
  require_text dist/opencode/AGENTS.md "$rule"
done

for guardrail in $GUARDRAILS; do
  require_file "guardrails/$guardrail.md"
  require_file "dist/claude-code/.claude/guardrails/$guardrail.md"
  require_file "dist/codex/.agents/guardrails/$guardrail.md"
  require_file "dist/cursor/.cursor/rules/$guardrail-guardrails.mdc"
  require_text "dist/claude-code/.claude/guardrails/$guardrail.md" "Knowledges Ingest Guardrails"
  require_text "dist/codex/.agents/guardrails/$guardrail.md" "Knowledges Ingest Guardrails"
  require_text "dist/cursor/.cursor/rules/$guardrail-guardrails.mdc" "Knowledges Ingest Guardrails"
  require_text dist/codex/AGENTS.md "$guardrail"
  require_text dist/gemini-cli/GEMINI.md "$guardrail"
  require_text dist/opencode/AGENTS.md "$guardrail"
done

require_text "dist/claude-code/.claude/skills/develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/codex/.agents/skills/develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/cursor/.cursor/rules/develop-task-flow.mdc" "Documentation Rules"
require_text dist/codex/AGENTS.md "Documentation Rules"
require_text dist/gemini-cli/GEMINI.md "Documentation Rules"
require_text dist/opencode/AGENTS.md "Documentation Rules"

require_text dist/codex/AGENTS.md "Scaffolded Procedures for AI Agents"
require_text dist/gemini-cli/GEMINI.md "Scaffolded Procedures for AI Agents"
require_text dist/opencode/AGENTS.md "Scaffolded Procedures for AI Agents"

if grep -R 'label: "content"' dist >/dev/null 2>&1; then
  fail 'dist contains label: "content"'
fi

if grep -R 'content:' dist >/dev/null 2>&1; then
  fail "dist contains content: autolabeler text"
fi

if grep -R 'agent-release-skill' dist >/dev/null 2>&1; then
  fail "dist contains forbidden agent-release-skill string"
fi

if grep -R -E 'back-merge|backmerge|백머지' dist >/dev/null 2>&1; then
  fail "dist contains forbidden back-merge text"
fi

if ! grep -R 'SPAI' dist >/dev/null 2>&1; then
  fail "dist does not contain SPAI"
fi

echo "dist validation ok"
