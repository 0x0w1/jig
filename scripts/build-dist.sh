#!/usr/bin/env sh
set -eu

SKILLS=$(awk -F '\t' '!/^#/ && NF >= 3 { printf "%s ", $1 }' manifest.tsv)

# Codex and Antigravity have no plugin system, so their skill directories carry a
# spai- prefix to stay out of the way of skills the user wrote. Claude Code needs no
# prefix: plugin skills are namespaced by the host as /spai:<skill>.
prefixed_skill_name() {
  case "$1" in
    spai-*) printf '%s' "$1" ;;
    *) printf 'spai-%s' "$1" ;;
  esac
}

skill_summary() {
  case "$1" in
    github-sync) printf '%s' "repository setup and synchronization; not for creating releases." ;;
    github-release) printf '%s' "release execution promoting develop to main with a fast-forward push and a tagged GitHub release." ;;
    develop-task-flow) printf '%s' "normal development tasks on feature/fix/chore branches squash-merged back into develop." ;;
    spai-update) printf '%s' "update the installed SPAI skills to the latest SPAI release and converge repository settings." ;;
    spai-doctor) printf '%s' "diagnose the installed SPAI state (version, protection, legacy); read-only." ;;
    *) printf '%s' "SPAI procedure." ;;
  esac
}

# Copies a skill payload, rewriting the frontmatter name so it matches the prefixed
# directory the installer creates.
copy_prefixed_skill() {
  copy_skill_id="$1"
  copy_skill_destination="$2"
  copy_skill_display=$(prefixed_skill_name "$copy_skill_id")
  awk -v name="$copy_skill_display" '
    NR == 1 && $0 == "---" { print; frontmatter = 1; next }
    frontmatter && /^name:/ { print "name: " name; next }
    frontmatter && $0 == "---" { print; frontmatter = 0; next }
    { print }
  ' "skills/$copy_skill_id/SKILL.md" > "$copy_skill_destination"
}

append_skill_list() {
  list_style="$1"
  for skill in $SKILLS; do
    case "$list_style" in
      plugin) printf -- '- `/spai:%s`: %s\n' "$skill" "$(skill_summary "$skill")" ;;
      prefixed) printf -- '- `%s`: %s\n' "$(prefixed_skill_name "$skill")" "$(skill_summary "$skill")" ;;
    esac
  done
}

append_managed_block() {
  block_intro="$1"
  block_style="$2"

  printf 'Scaffolded Procedures for AI Agents\n\n'
  printf '<!-- spai:start github-release-setup -->\n'
  printf '<!-- spai:version dev -->\n\n'
  printf '%s\n\n' "$block_intro"
  append_skill_list "$block_style"
  printf '\n%s\n' "Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation."
  printf '\n<!-- spai:end github-release-setup -->\n'
}

rm -rf dist

mkdir -p \
  dist/claude-code \
  dist/codex/.agents/skills \
  dist/antigravity/.agents/skills

cp manifest.tsv dist/manifest.tsv

append_managed_block \
  "SPAI ships these repository workflow skills through the spai Claude Code plugin. Plugin skills are namespaced, so they never collide with skills you wrote yourself." \
  plugin > dist/claude-code/CLAUDE.md

append_managed_block \
  "SPAI installs these repository workflow skills under .agents/skills. Every SPAI skill name carries the spai- prefix so it stays out of the way of skills you wrote yourself." \
  prefixed > dist/codex/AGENTS.md

append_managed_block \
  "SPAI installs these repository workflow skills under .agents/skills. Every SPAI skill name carries the spai- prefix so it stays out of the way of skills you wrote yourself." \
  prefixed > dist/antigravity/GEMINI.md

for skill in $SKILLS; do
  prefixed=$(prefixed_skill_name "$skill")
  for target_dir in dist/codex/.agents/skills dist/antigravity/.agents/skills; do
    mkdir -p "$target_dir/$prefixed"
    copy_prefixed_skill "$skill" "$target_dir/$prefixed/SKILL.md"
  done
done

build_claude_plugin() {
  plugin_name="$1"
  plugin_root="dist/claude-code-plugin/$plugin_name"
  mkdir -p "$plugin_root/.claude-plugin"
  cat > "$plugin_root/.claude-plugin/plugin.json" <<EOF
{
  "name": "$plugin_name",
  "description": "SPAI repository workflow skills: develop task flow, CLI releases, and repository sync",
  "author": { "name": "0x0w1" },
  "homepage": "https://github.com/0x0w1/spai",
  "license": "MIT"
}
EOF
  for skill in $SKILLS; do
    mkdir -p "$plugin_root/skills/$skill"
    cp "skills/$skill/SKILL.md" "$plugin_root/skills/$skill/SKILL.md"
  done
}

build_claude_plugin spai

echo "Generated dist files:"
find dist -type f | sort
