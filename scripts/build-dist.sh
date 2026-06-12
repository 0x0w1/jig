#!/usr/bin/env sh
set -eu

SKILL_FILES="skills/github-release-setup/files"
SKILLS="github-sync github-release develop-task-flow knowledges-quick-ingest"
RULES="knowledges-raw-contract"
GUARDRAILS="knowledges-ingest"

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

append_branded_managed_header() {
  cat <<'EOF'
# SPAI

Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release/vX.Y.Z execution from develop to main.
- `develop-task-flow`: normal development tasks from develop through a PR back to develop.
- `knowledges-quick-ingest`: send small project knowledge into a configured LLM + Obsidian + Graphify knowledges git repository.

EOF
}

append_managed_header() {
  cat <<'EOF'
Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release/vX.Y.Z execution from develop to main.
- `develop-task-flow`: normal development tasks from develop through a PR back to develop.
- `knowledges-quick-ingest`: send small project knowledge into a configured LLM + Obsidian + Graphify knowledges git repository.

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

append_all_rule_bodies() {
  for rule in $RULES; do
    rule_file="rules/$rule.md"
    if [ ! -f "$rule_file" ]; then
      echo "Missing $rule_file" >&2
      exit 1
    fi
    printf '\n## rule: %s\n\n' "$rule"
    cat "$rule_file"
  done
}

append_all_guardrail_bodies() {
  for guardrail in $GUARDRAILS; do
    guardrail_file="guardrails/$guardrail.md"
    if [ ! -f "$guardrail_file" ]; then
      echo "Missing $guardrail_file" >&2
      exit 1
    fi
    printf '\n## guardrail: %s\n\n' "$guardrail"
    cat "$guardrail_file"
  done
}

rm -rf dist

mkdir -p \
  dist/github/workflows \
  dist/claude-code/.claude/skills \
  dist/claude-code/.claude/rules \
  dist/claude-code/.claude/guardrails \
  dist/codex/.agents/skills \
  dist/codex/.agents/rules \
  dist/codex/.agents/guardrails \
  dist/cursor/.cursor/rules \
  dist/gemini-cli \
  dist/opencode

cp "$SKILL_FILES/drafter-config.yaml" dist/github/drafter-config.yaml
cp "$SKILL_FILES/drafter.yaml" dist/github/workflows/drafter.yaml
cp "$SKILL_FILES/PULL_REQUEST_TEMPLATE.md" dist/github/PULL_REQUEST_TEMPLATE.md

cat > dist/claude-code/CLAUDE.md <<'EOF'
Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->

SPAI installs reusable project skills for repository release and development workflows.

Available Claude Code skills:

- `/github-sync`: repository setup and synchronization; not for creating releases.
- `/github-release`: release/vX.Y.Z execution from develop to main.
- `/develop-task-flow`: normal development tasks from develop through a PR back to develop.
- `/knowledges-quick-ingest`: send small project knowledge into a configured LLM + Obsidian + Graphify knowledges git repository.

Additional knowledges rules and guardrails are installed under `.claude/rules/` and `.claude/guardrails/`.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
EOF

for skill in $SKILLS; do
  mkdir -p "dist/claude-code/.claude/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/claude-code/.claude/skills/$skill/SKILL.md"
done

for rule in $RULES; do
  cp "rules/$rule.md" "dist/claude-code/.claude/rules/$rule.md"
done

for guardrail in $GUARDRAILS; do
  cp "guardrails/$guardrail.md" "dist/claude-code/.claude/guardrails/$guardrail.md"
done

for skill in $SKILLS; do
  mkdir -p "dist/codex/.agents/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/codex/.agents/skills/$skill/SKILL.md"
done
for rule in $RULES; do
  cp "rules/$rule.md" "dist/codex/.agents/rules/$rule.md"
done
for guardrail in $GUARDRAILS; do
  cp "guardrails/$guardrail.md" "dist/codex/.agents/guardrails/$guardrail.md"
done
{
  append_managed_header
  append_all_skill_bodies
  append_all_rule_bodies
  append_all_guardrail_bodies
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

for rule in $RULES; do
  rule_file="dist/cursor/.cursor/rules/$rule.mdc"
  {
    printf '%s\n' '---'
    printf 'description: "Knowledges raw Markdown contract for LLM + Obsidian + Graphify git repository ingestion."\n'
    printf '%s\n' 'globs:'
    printf '%s\n' '  - "**/*"'
    printf '%s\n' 'alwaysApply: false'
    printf '%s\n\n' '---'
    cat "rules/$rule.md"
  } > "$rule_file"
done

for guardrail in $GUARDRAILS; do
  rule_file="dist/cursor/.cursor/rules/$guardrail-guardrails.mdc"
  {
    printf '%s\n' '---'
    printf 'description: "Knowledges ingest safety, privacy, cost, and Graphify guardrails."\n'
    printf '%s\n' 'globs:'
    printf '%s\n' '  - "**/*"'
    printf '%s\n' 'alwaysApply: false'
    printf '%s\n\n' '---'
    cat "guardrails/$guardrail.md"
  } > "$rule_file"
done

{
  append_branded_managed_header
  append_all_skill_bodies
  append_all_rule_bodies
  append_all_guardrail_bodies
  append_managed_footer
} > dist/gemini-cli/GEMINI.md

{
  append_managed_header
  append_all_skill_bodies
  append_all_rule_bodies
  append_all_guardrail_bodies
  append_managed_footer
} > dist/opencode/AGENTS.md

echo "Generated dist files:"
find dist -type f | sort
