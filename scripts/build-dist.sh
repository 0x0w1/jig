#!/usr/bin/env sh
set -eu

PROMPT="skills/github-release-setup/prompt.md"
SKILL_FILES="skills/github-release-setup/files"

if [ ! -f "$PROMPT" ]; then
  echo "Missing $PROMPT" >&2
  exit 1
fi

rm -rf dist

mkdir -p \
  dist/claude-code/skills/github-release-setup/files \
  dist/codex \
  dist/cursor/.cursor/rules \
  dist/gemini-cli \
  dist/opencode

cat > dist/claude-code/skills/github-release-setup/SKILL.md <<'EOF'
---
description: Configure a GitHub repository with protected main/develop branches, standardized labels, Release Drafter, and safe sync/release procedures.
---

EOF
cat "$PROMPT" >> dist/claude-code/skills/github-release-setup/SKILL.md
cp "$SKILL_FILES/drafter-config.yaml" dist/claude-code/skills/github-release-setup/files/drafter-config.yaml
cp "$SKILL_FILES/drafter.yaml" dist/claude-code/skills/github-release-setup/files/drafter.yaml

cat > dist/codex/AGENTS.md <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

EOF
cat "$PROMPT" >> dist/codex/AGENTS.md
cat >> dist/codex/AGENTS.md <<'EOF'

<!-- spai:end github-release-setup -->
EOF

cat > dist/cursor/.cursor/rules/github-release-setup.mdc <<'EOF'
---
description: Configure GitHub repository release setup with Release Drafter, labels, branch protection, and safe workflow rules.
globs:
  - "**/*"
alwaysApply: false
---

EOF
cat "$PROMPT" >> dist/cursor/.cursor/rules/github-release-setup.mdc

cat > dist/gemini-cli/GEMINI.md <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

EOF
cat "$PROMPT" >> dist/gemini-cli/GEMINI.md
cat >> dist/gemini-cli/GEMINI.md <<'EOF'

<!-- spai:end github-release-setup -->
EOF

cat > dist/opencode/AGENTS.md <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

EOF
cat "$PROMPT" >> dist/opencode/AGENTS.md
cat >> dist/opencode/AGENTS.md <<'EOF'

<!-- spai:end github-release-setup -->
EOF

echo "Generated dist files:"
find dist -type f | sort
