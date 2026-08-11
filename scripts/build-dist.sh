#!/usr/bin/env sh
set -eu

SKILLS=$(awk -F '\t' '!/^#/ && NF >= 3 { printf "%s ", $1 }' manifest.tsv)
PLUGIN_SKILLS="github-sync github-release develop-task-flow"

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
Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI installs repository release and development workflows as durable instructions.

Available procedures:

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `spai-doctor`: diagnose the installed SPAI state (version, drift, protection, legacy); read-only.

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
  dist/claude-code/.claude/skills \
  dist/codex/.agents/skills \
  dist/antigravity/.agents/skills

cp manifest.tsv dist/manifest.tsv

cat > dist/claude-code/CLAUDE.md <<'EOF'
Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI installs reusable project skills for repository release and development workflows.

Available Claude Code skills:

- `/github-sync`: repository setup and synchronization; not for creating releases.
- `/github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `/develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `/spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `/spai-doctor`: diagnose the installed SPAI state (version, drift, protection, legacy); read-only.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
EOF

for skill in $SKILLS; do
  mkdir -p "dist/claude-code/.claude/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/claude-code/.claude/skills/$skill/"
done

for skill in $SKILLS; do
  mkdir -p "dist/codex/.agents/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/codex/.agents/skills/$skill/"
done
{
  append_managed_header
  append_all_skill_bodies
  append_managed_footer
} > dist/codex/AGENTS.md

cat > dist/antigravity/GEMINI.md <<'EOF'
Scaffolded Procedures for AI Agents

<!-- spai:start github-release-setup -->
<!-- spai:version dev -->

SPAI installs reusable project skills for repository release and development workflows.

Available Antigravity skills (discovered from .agents/skills):

- `github-sync`: repository setup and synchronization; not for creating releases.
- `github-release`: release execution promoting develop to main with a fast-forward push and a tagged GitHub release.
- `develop-task-flow`: normal development tasks on feature/fix/chore branches squash-merged back into develop.
- `spai-update`: update the installed SPAI skills to the latest SPAI release and converge repository settings.
- `spai-doctor`: diagnose the installed SPAI state (version, drift, protection, legacy); read-only.

Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation.

<!-- spai:end github-release-setup -->
EOF

for skill in $SKILLS; do
  mkdir -p "dist/antigravity/.agents/skills/$skill"
  cp "skills/$skill/SKILL.md" "dist/antigravity/.agents/skills/$skill/"
done

build_claude_plugin() {
  plugin_name="$1"
  plugin_root="dist/claude-code-plugin/$plugin_name"
  mkdir -p "$plugin_root/.claude-plugin"
  cat > "$plugin_root/.claude-plugin/plugin.json" <<EOF
{
  "name": "$plugin_name",
  "description": "SPAI solo-cli workflow skills: github-sync, github-release, develop-task-flow",
  "author": { "name": "0x0w1" },
  "homepage": "https://github.com/0x0w1/spai",
  "license": "MIT"
}
EOF
  for skill in $PLUGIN_SKILLS; do
    mkdir -p "$plugin_root/skills/$skill"
    cp "skills/$skill/SKILL.md" "$plugin_root/skills/$skill/SKILL.md"
  done
}

build_claude_plugin spai

echo "Generated dist files:"
find dist -type f | sort
