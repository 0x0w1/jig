#!/usr/bin/env sh
set -eu

SKILLS="github-sync github-release develop-task-flow"

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
    *) fail "unknown skill: $1" ;;
  esac
}

require_file dist/github/drafter-config.yaml
require_file dist/github/workflows/drafter.yaml

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
