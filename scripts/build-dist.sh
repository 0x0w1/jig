#!/usr/bin/env sh
set -eu

SKILL_FILES="skills/github-release-setup/files"
SKILLS="github-sync github-release develop-task-flow"

skill_description() {
  skill_file="$1"
  sed -n 's/^description:[[:space:]]*//p' "$skill_file" | head -n 1 | sed 's/^"//; s/"$//'
}

yaml_quote() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_skill_body() {
  skill_file="$1"
  awk '
    NR == 1 && $0 == "---" {
      frontmatter = 1
      next
    }
    frontmatter && $0 == "---" {
      frontmatter = 0
      next
    }
    !frontmatter {
      print
    }
  ' "$skill_file"
}

append_managed_header() {
  cat <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release/vX.Y.Z execution from develop to main.
- `develop-task-flow`: normal development tasks from develop through a PR back to develop.

EOF
}

append_managed_footer() {
  cat <<'EOF'

<!-- spai:end github-release-setup -->
EOF
}

append_all_skill_bodies() {
  for skill in $SKILLS; do
    skill_file="skills/$skill/SKILL.md"
    if [ ! -f "$skill_file" ]; then
      echo "Missing $skill_file" >&2
      exit 1
    fi
    printf '\n## %s\n\n' "$skill"
    append_skill_body "$skill_file"
  done
}

rm -rf dist

mkdir -p \
  dist/github/workflows \
  dist/claude-code/.claude/skills \
  dist/codex/.agents/skills \
  dist/cursor/.cursor/rules \
  dist/gemini-cli \
  dist/opencode

cp "$SKILL_FILES/drafter-config.yaml" dist/github/drafter-config.yaml
cp "$SKILL_FILES/drafter.yaml" dist/github/workflows/drafter.yaml

cat > dist/claude-code/CLAUDE.md <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs reusable project skills for repository release and development workflows.

Available Claude Code skills:

- `/github-sync`: repository setup and synchronization; not for creating releases.
- `/github-release`: release/vX.Y.Z execution from develop to main.
- `/develop-task-flow`: normal development tasks from develop through a PR back to develop.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
EOF

for skill in $SKILLS; do
  mkdir -p "dist/claude-code/.claude/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/claude-code/.claude/skills/$skill/SKILL.md"
done

for skill in $SKILLS; do
  mkdir -p "dist/codex/.agents/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/codex/.agents/skills/$skill/SKILL.md"
done
{
  append_managed_header
  append_all_skill_bodies
  append_managed_footer
} > dist/codex/AGENTS.md

for skill in $SKILLS; do
  skill_file="skills/$skill/SKILL.md"
  description=$(skill_description "$skill_file")
  rule_file="dist/cursor/.cursor/rules/$skill.mdc"
  {
    printf '%s\n' '---'
    printf 'description: "%s"\n' "$(yaml_quote "$description")"
    printf '%s\n' 'globs:'
    printf '%s\n' '  - "**/*"'
    printf '%s\n' 'alwaysApply: false'
    printf '%s\n\n' '---'
    append_skill_body "$skill_file"
  } > "$rule_file"
done

{
  append_managed_header
  append_all_skill_bodies
  append_managed_footer
} > dist/gemini-cli/GEMINI.md

{
  append_managed_header
  append_all_skill_bodies
  append_managed_footer
} > dist/opencode/AGENTS.md

echo "Generated dist files:"
find dist -type f | sort
