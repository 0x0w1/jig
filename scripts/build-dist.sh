#!/usr/bin/env sh
set -eu

SKILLS=$(awk -F '\t' '!/^#/ && NF >= 3 { printf "%s ", $1 }' manifest.tsv)

# Codex and Antigravity have no plugin system, so their skill directories carry a
# jig- prefix to stay out of the way of skills the user wrote. Claude Code needs no
# prefix: plugin skills are namespaced by the host as /jig:<skill>.
prefixed_skill_name() {
  case "$1" in
    jig-*) printf '%s' "$1" ;;
    *) printf 'jig-%s' "$1" ;;
  esac
}

skill_summary() {
  case "$1" in
    github-sync) printf '%s' "repository setup and synchronization; not for creating releases." ;;
    github-release) printf '%s' "release execution promoting develop to main with a fast-forward push and a tagged GitHub release." ;;
    develop-task-flow) printf '%s' "normal development tasks on feature/fix/chore branches squash-merged back into develop." ;;
    jig-setup) printf '%s' "install jig for a repository and select its GitHub CLI profile without changing the global active account." ;;
    jig-update) printf '%s' "update the installed jig skills to the latest jig release and converge repository settings." ;;
    jig-doctor) printf '%s' "diagnose every installed jig target and scope plus repository profile, version, protection, and legacy state; read-only." ;;
    readme) printf '%s' "write or update the project README from the repository state; drafts one when missing, fixes drift when present." ;;
    version-rubric) printf '%s' "decide and maintain how this project grades patch, minor, and major in .jig/versioning.md; ships the project-type rubric catalog." ;;
    rubric-scan) printf '%s' "scan the repository to classify its project type and recommend a version rubric from the catalog; read-only." ;;
    conformance-audit) printf '%s' "audit the history against the procedure: commit subjects, release grades, tags, and the main/develop invariant; read-only." ;;
    *) printf '%s' "jig procedure." ;;
  esac
}

# Lists every file a skill ships, relative to its directory, with SKILL.md first.
# A skill is a directory, not a single file: version-rubric carries its rubric catalog.
skill_files() {
  printf 'SKILL.md\n'
  find "skills/$1" -type f ! -name SKILL.md | sed "s|^skills/$1/||" | LC_ALL=C sort
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
  for skill in $SKILLS; do
    printf -- '- `%s`: %s\n' "$(prefixed_skill_name "$skill")" "$(skill_summary "$skill")"
  done
}

# Only codex and antigravity get a managed block. Claude Code loads the plugin's skills
# natively, so a rules-file skill list there would only duplicate the plugin metadata.
append_managed_block() {
  block_intro="$1"

  printf 'jig - repository procedures for AI agent CLIs\n\n'
  printf '<!-- jig:start github-release-setup -->\n'
  printf '<!-- jig:version dev -->\n\n'
  printf '%s\n\n' "$block_intro"
  append_skill_list
  printf '\n%s\n' "Use these skills when the matching workflow is requested. Preserve unrelated user changes, never force push, and never delete branches or labels without explicit confirmation."
  printf '\n<!-- jig:end github-release-setup -->\n'
}

rm -rf dist

mkdir -p \
  dist/codex/.agents/skills \
  dist/antigravity/.agents/skills

cp manifest.tsv dist/manifest.tsv

append_managed_block \
  "jig installs these repository workflow skills under .agents/skills. Every jig skill name carries the jig- prefix so it stays out of the way of skills you wrote yourself." \
  > dist/codex/AGENTS.md

append_managed_block \
  "jig installs these repository workflow skills under .agents/skills. Every jig skill name carries the jig- prefix so it stays out of the way of skills you wrote yourself." \
  > dist/antigravity/GEMINI.md

# The installer downloads one file at a time, so it needs the file list the payload
# actually has. Paths are relative to the skill directory and identical for every target.
{
  printf '# skill\tpath\n'
  for skill in $SKILLS; do
    for skill_file in $(skill_files "$skill"); do
      printf '%s\t%s\n' "$skill" "$skill_file"
    done
  done
} > dist/files.tsv

for skill in $SKILLS; do
  prefixed=$(prefixed_skill_name "$skill")
  for target_dir in dist/codex/.agents/skills dist/antigravity/.agents/skills; do
    for skill_file in $(skill_files "$skill"); do
      destination="$target_dir/$prefixed/$skill_file"
      mkdir -p "$(dirname "$destination")"
      if [ "$skill_file" = "SKILL.md" ]; then
        copy_prefixed_skill "$skill" "$destination"
      else
        cp "skills/$skill/$skill_file" "$destination"
      fi
    done
  done
done

build_claude_plugin() {
  plugin_name="$1"
  plugin_root="dist/claude-code-plugin/$plugin_name"
  mkdir -p "$plugin_root/.claude-plugin"
  cat > "$plugin_root/.claude-plugin/plugin.json" <<EOF
{
  "name": "$plugin_name",
  "description": "jig repository workflow skills: project setup, develop flow, CLI releases, repository sync, and lifecycle management",
  "author": { "name": "0x0w1" },
  "homepage": "https://github.com/0x0w1/jig",
  "license": "MIT"
}
EOF
  mkdir -p "$plugin_root/hooks"
  cp hooks/hooks.json "$plugin_root/hooks/hooks.json"
  cp hooks/guard-push.sh "$plugin_root/hooks/guard-push.sh"
  chmod +x "$plugin_root/hooks/guard-push.sh"
  for skill in $SKILLS; do
    for skill_file in $(skill_files "$skill"); do
      destination="$plugin_root/skills/$skill/$skill_file"
      mkdir -p "$(dirname "$destination")"
      cp "skills/$skill/$skill_file" "$destination"
    done
  done
}

build_claude_plugin jig

echo "Generated dist files:"
find dist -type f | sort
