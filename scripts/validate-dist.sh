#!/usr/bin/env sh
set -eu

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

require_file dist/claude-code/skills/github-release-setup/SKILL.md
require_file dist/claude-code/skills/github-release-setup/files/drafter-config.yaml
require_file dist/claude-code/skills/github-release-setup/files/drafter.yaml
require_file dist/codex/AGENTS.md
require_file dist/cursor/.cursor/rules/github-release-setup.mdc
require_file dist/gemini-cli/GEMINI.md
require_file dist/opencode/AGENTS.md

require_text dist/claude-code/skills/github-release-setup/SKILL.md "GitHub Release Setup Skill"
require_text dist/codex/AGENTS.md "spai:start github-release-setup"
require_text dist/codex/AGENTS.md "spai:end github-release-setup"
require_text dist/gemini-cli/GEMINI.md "spai:start github-release-setup"
require_text dist/gemini-cli/GEMINI.md "spai:end github-release-setup"
require_text dist/opencode/AGENTS.md "spai:start github-release-setup"
require_text dist/opencode/AGENTS.md "spai:end github-release-setup"
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

if ! grep -R 'SPAI' dist >/dev/null 2>&1; then
  fail "dist does not contain SPAI"
fi

echo "dist validation ok"
