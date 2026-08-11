#!/usr/bin/env sh
set -eu

SKILLS=$(awk -F '\t' '!/^#/ && NF >= 3 { printf "%s ", $1 }' manifest.tsv)

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
    spai-update) printf '%s\n' "# SPAI Update" ;;
    spai-doctor) printf '%s\n' "# SPAI Doctor" ;;
    *) fail "unknown skill: $1" ;;
  esac
}

if [ -e dist/github ]; then
  fail "dist/github must not exist: the CLI release flow ships no GitHub workflow files"
fi

require_file dist/manifest.tsv
require_text dist/manifest.tsv "develop-task-flow"

require_file dist/claude-code/CLAUDE.md
require_text dist/claude-code/CLAUDE.md "spai:start github-release-setup"
require_text dist/claude-code/CLAUDE.md "spai:end github-release-setup"
require_text dist/claude-code/CLAUDE.md "<!-- spai:version dev -->"

require_file dist/codex/AGENTS.md
require_text dist/codex/AGENTS.md "spai:start github-release-setup"
require_text dist/codex/AGENTS.md "spai:end github-release-setup"
require_text dist/codex/AGENTS.md "<!-- spai:version dev -->"

require_file dist/antigravity/GEMINI.md
require_text dist/antigravity/GEMINI.md "spai:start github-release-setup"
require_text dist/antigravity/GEMINI.md "spai:end github-release-setup"
require_text dist/antigravity/GEMINI.md "<!-- spai:version dev -->"

for skill in $SKILLS; do
  title=$(skill_title "$skill")
  require_file "dist/claude-code/.claude/skills/$skill/SKILL.md"
  require_file "dist/codex/.agents/skills/$skill/SKILL.md"
  require_file "dist/antigravity/.agents/skills/$skill/SKILL.md"
  require_text "dist/claude-code/.claude/skills/$skill/SKILL.md" "$title"
  require_text "dist/codex/.agents/skills/$skill/SKILL.md" "$title"
  require_text "dist/antigravity/.agents/skills/$skill/SKILL.md" "$title"
  require_text dist/codex/AGENTS.md "$skill"
  require_text dist/antigravity/GEMINI.md "$skill"
done

require_text "dist/claude-code/.claude/skills/develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/codex/.agents/skills/develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/antigravity/.agents/skills/develop-task-flow/SKILL.md" "Documentation Rules"
require_text dist/codex/AGENTS.md "Documentation Rules"

require_text "dist/claude-code/.claude/skills/github-release/SKILL.md" "Develop-First Gate"
require_text "dist/codex/.agents/skills/github-release/SKILL.md" "Develop-First Gate"
require_text "dist/antigravity/.agents/skills/github-release/SKILL.md" "Develop-First Gate"
require_text dist/codex/AGENTS.md "Develop-First Gate"

require_text "dist/claude-code/.claude/skills/github-release/SKILL.md" 'git push origin develop:main'
require_text "dist/codex/.agents/skills/github-release/SKILL.md" 'git push origin develop:main'
require_text "dist/antigravity/.agents/skills/github-release/SKILL.md" 'git push origin develop:main'
require_text dist/codex/AGENTS.md 'git push origin develop:main'

require_text "dist/claude-code/.claude/skills/github-release/SKILL.md" 'gh release create'
require_text "dist/antigravity/.agents/skills/github-release/SKILL.md" 'gh release create'
require_text "dist/claude-code/.claude/skills/develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/codex/.agents/skills/develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/antigravity/.agents/skills/develop-task-flow/SKILL.md" 'git merge --squash'

require_text dist/codex/AGENTS.md "Scaffolded Procedures for AI Agents"
require_text dist/antigravity/GEMINI.md "Scaffolded Procedures for AI Agents"

require_file .claude-plugin/marketplace.json
require_text .claude-plugin/marketplace.json '"./dist/claude-code-plugin/spai"'

require_file "dist/claude-code-plugin/spai/.claude-plugin/plugin.json"
require_text "dist/claude-code-plugin/spai/.claude-plugin/plugin.json" '"name": "spai"'
for skill in github-sync github-release develop-task-flow; do
  require_file "dist/claude-code-plugin/spai/skills/$skill/SKILL.md"
done
require_text "dist/claude-code-plugin/spai/skills/develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/claude-code-plugin/spai/skills/github-release/SKILL.md" 'git push origin develop:main'

if find dist -name "SKILL.*.md" ! -name "SKILL.md" | grep -q .; then
  fail "dist must contain only resolved SKILL.md files: solo-cli is the only flow"
fi

if grep -R 'team-pr' dist .claude-plugin manifest.tsv >/dev/null 2>&1; then
  fail "team-pr is not a supported flow; see docs/roadmap.md"
fi

if grep -R 'agent-release-skill' dist >/dev/null 2>&1; then
  fail "dist contains forbidden agent-release-skill string"
fi

if grep -R -E 'back-merge|backmerge|백머지' dist >/dev/null 2>&1; then
  fail "dist contains forbidden back-merge text"
fi

if grep -R 'release-drafter/release-drafter' dist >/dev/null 2>&1; then
  fail "dist contains a release-drafter workflow reference"
fi

if ! grep -R 'SPAI' dist >/dev/null 2>&1; then
  fail "dist does not contain SPAI"
fi

echo "dist validation ok"
