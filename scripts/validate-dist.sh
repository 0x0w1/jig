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
    project-setup) printf '%s\n' "# Project Setup" ;;
    spai-update) printf '%s\n' "# SPAI Update" ;;
    spai-doctor) printf '%s\n' "# SPAI Doctor" ;;
    readme) printf '%s\n' "# README" ;;
    version-rubric) printf '%s\n' "# Version Rubric" ;;
    rubric-scan) printf '%s\n' "# Rubric Scan" ;;
    *) fail "unknown skill: $1" ;;
  esac
}

if [ -e dist/github ]; then
  fail "dist/github must not exist: the CLI release flow ships no GitHub workflow files"
fi

require_file dist/manifest.tsv
require_text dist/manifest.tsv "develop-task-flow"
require_text install.sh "spai.githubProfile"
require_text install.sh "gh auth token"
require_text install.sh "GitHub profile is optional during installation"
require_text install.sh "repository settings sync is deferred to project-setup"

if ! sh -n install.sh; then
  fail "install.sh has invalid shell syntax"
fi

if grep -F 'gh auth switch' install.sh >/dev/null 2>&1; then
  fail "install.sh must select a GitHub profile per command, not mutate the global active account"
fi

if grep -F 'project scope requires --github-profile' install.sh >/dev/null 2>&1; then
  fail "project installation must finish before GitHub profile setup"
fi

require_file dist/codex/AGENTS.md
require_text dist/codex/AGENTS.md "spai:start github-release-setup"
require_text dist/codex/AGENTS.md "spai:end github-release-setup"
require_text dist/codex/AGENTS.md "<!-- spai:version dev -->"

require_file dist/antigravity/GEMINI.md
require_text dist/antigravity/GEMINI.md "spai:start github-release-setup"
require_text dist/antigravity/GEMINI.md "spai:end github-release-setup"
require_text dist/antigravity/GEMINI.md "<!-- spai:version dev -->"

prefixed_skill_name() {
  case "$1" in
    spai-*) printf '%s' "$1" ;;
    *) printf 'spai-%s' "$1" ;;
  esac
}

if [ -e dist/claude-code ]; then
  fail "install.sh does not target claude-code: it ships the spai plugin under dist/claude-code-plugin instead"
fi

for skill in $SKILLS; do
  title=$(skill_title "$skill")
  prefixed=$(prefixed_skill_name "$skill")

  require_file "dist/codex/.agents/skills/$prefixed/SKILL.md"
  require_file "dist/antigravity/.agents/skills/$prefixed/SKILL.md"
  require_text "dist/codex/.agents/skills/$prefixed/SKILL.md" "$title"
  require_text "dist/antigravity/.agents/skills/$prefixed/SKILL.md" "$title"
  require_text "dist/codex/.agents/skills/$prefixed/SKILL.md" "name: $prefixed"
  require_text "dist/antigravity/.agents/skills/$prefixed/SKILL.md" "name: $prefixed"

  require_text dist/codex/AGENTS.md "\`$prefixed\`"
  require_text dist/antigravity/GEMINI.md "\`$prefixed\`"

  require_file "dist/claude-code-plugin/spai/skills/$skill/SKILL.md"
  require_text "dist/claude-code-plugin/spai/skills/$skill/SKILL.md" "$title"
done

require_text "dist/codex/.agents/skills/spai-develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/antigravity/.agents/skills/spai-develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/codex/.agents/skills/spai-develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/antigravity/.agents/skills/spai-develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/codex/.agents/skills/spai-github-release/SKILL.md" "Develop-First Gate"
require_text "dist/codex/.agents/skills/spai-github-release/SKILL.md" 'git push origin develop:main'
require_text "dist/antigravity/.agents/skills/spai-github-release/SKILL.md" 'gh release create'

# The version rubric is a contract between four skills: version-rubric owns the file,
# github-release reads it, project-setup delegates to it, spai-doctor reports it.
for rubric_skill in github-release project-setup spai-doctor version-rubric; do
  require_text "dist/claude-code-plugin/spai/skills/$rubric_skill/SKILL.md" ".spai/versioning.md"
  require_text "dist/codex/.agents/skills/$(prefixed_skill_name "$rubric_skill")/SKILL.md" ".spai/versioning.md"
done

for rubric_skill in github-release spai-doctor version-rubric; do
  require_text "dist/claude-code-plugin/spai/skills/$rubric_skill/SKILL.md" "## Decision Order"
  require_text "dist/claude-code-plugin/spai/skills/$rubric_skill/SKILL.md" "## Grade Definitions"
done

# The section titles went English while rubrics already written in Korean stay valid.
# Every skill that reads a rubric must still name the legacy spelling, or those files
# silently read as contract-broken.
for rubric_skill in github-release spai-doctor version-rubric; do
  require_text "dist/claude-code-plugin/spai/skills/$rubric_skill/SKILL.md" "## 판정 순서"
  require_text "dist/claude-code-plugin/spai/skills/$rubric_skill/SKILL.md" "## 등급 정의"
done
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "> 기준:"
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "> Basis:"

# version-rubric ships the whole default rubric; the other skills must not copy it.
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "a fix inside what the project already does"
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "everything they already do keeps working"
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "must a human step in to keep using it"
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "## Hard Rules"
require_text "dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md" "## Version Format"

# The fallback inside github-release must stay identical to the default version-rubric
# writes, or a project grades differently depending on which skills happen to be installed.
require_text "dist/claude-code-plugin/spai/skills/github-release/SKILL.md" "must a human step in to keep using it"
require_text "dist/claude-code-plugin/spai/skills/github-release/SKILL.md" "changes when the agent speaks is at least"
require_text "dist/codex/.agents/skills/spai-version-rubric/SKILL.md" "SPAI_VERSION_RUBRIC"
require_text "dist/antigravity/.agents/skills/spai-version-rubric/SKILL.md" "spai.versionRubric"

if grep -F 'must a human step in to keep using it' dist/claude-code-plugin/spai/skills/project-setup/SKILL.md >/dev/null 2>&1; then
  fail "project-setup must delegate to version-rubric, not duplicate the default rubric"
fi

# The rubric moved SPAI's own facts out of the distributed release skill. Keep them out.
for own_fact in 'scripts/validate-dist.sh' 'spai@spai' '0x0w1/spai' '--target'; do
  if grep -F "$own_fact" dist/claude-code-plugin/spai/skills/github-release/SKILL.md >/dev/null 2>&1; then
    fail "dist github-release leaks a SPAI-specific fact: $own_fact"
  fi
done

# This repository's own rubric is the normative source for its releases.
require_file .spai/versioning.md
require_text .spai/versioning.md "## 판정 순서"
require_text .spai/versioning.md "## 등급 정의"
require_text .spai/versioning.md "## 강경 규칙"
require_text .spai/versioning.md "sh scripts/validate-dist.sh"
require_file docs/version-rubric.md
require_text docs/version-rubric.md "skills/version-rubric/rubrics/INDEX.md"
require_text README.md "docs/version-rubric.md"

# README.md is the English canonical; README.ko.md is the Korean mirror. Each links the other,
# so a reader landing on either one can switch.
require_file README.ko.md
require_file docs/assets/quick-start.svg
# A skill-name table is fine; a lopsided one is not. GitHub sizes table columns by
# content, so a description several times longer than the identifier squeezes the name
# column until `develop-task-flow` wraps mid-word. awk counts bytes here, so the limit
# leaves room for Korean text while still catching a description that has run away.
for readme_file in README.md README.ko.md; do
  awk -v file="$readme_file" -F '|' '
    /^\| `[a-z-]+` \|/ {
      description = $3
      gsub(/^ +| +$/, "", description)
      if (length(description) > 90) { print file ": " description; found = 1 }
    }
    END { exit found ? 1 : 0 }
  ' "$readme_file" || fail "skill table description is too long (see line above); trim it or switch the section to a list"
done

require_text README.md "docs/assets/quick-start.svg"
require_text README.ko.md "docs/assets/quick-start.svg"
# The diagram is read on light and dark GitHub themes; both palettes must stay defined.
require_text docs/assets/quick-start.svg "prefers-color-scheme: dark"
require_text docs/assets/quick-start.svg "role=\"img\""
require_text docs/assets/quick-start.svg "aria-label"

require_text README.md "[한국어](README.ko.md)"
require_text README.ko.md "[English](README.md)"
# Canary words rather than a [가-힣] range: BSD grep matches such ranges bytewise, so an
# em dash counts as Korean and the check fires on correct English prose.
for korean_canary in 스킬 설치 저장소 버전 릴리즈 판정; do
  if grep -F "$korean_canary" README.md >/dev/null 2>&1; then
    fail "README.md is the English version: move Korean prose to README.ko.md (found: $korean_canary)"
  fi
done

# A skill is a directory: dist/files.tsv is what tells the installer which files to fetch.
require_file dist/files.tsv
require_text dist/files.tsv "version-rubric	rubrics/INDEX.md"
require_text dist/files.tsv "rubric-scan	SKILL.md"

for catalog_file in \
  rubrics/INDEX.md \
  rubrics/_template.md \
  rubrics/common.md \
  rubrics/api-server.md \
  rubrics/infrastructure.md \
  rubrics/agent-skill-pack.md \
  rubrics/document-archive.md \
  rubrics/content-site.md \
  rubrics/dataset.md; do
  require_text dist/files.tsv "version-rubric	$catalog_file"
  require_file "dist/claude-code-plugin/spai/skills/version-rubric/$catalog_file"
  require_file "dist/codex/.agents/skills/spai-version-rubric/$catalog_file"
  require_file "dist/antigravity/.agents/skills/spai-version-rubric/$catalog_file"
done

# Every catalog row must point at a file that exists, or the scan recommends a dead link.
awk -F '|' '/^\| \[/ { print $2 }' skills/version-rubric/rubrics/INDEX.md \
  | sed -e 's/.*(\(.*\)).*/\1/' -e 's/^[[:space:]]*//' \
  | while read -r indexed_rubric; do
      [ -n "$indexed_rubric" ] || continue
      [ -f "skills/version-rubric/rubrics/$indexed_rubric" ] \
        || fail "INDEX.md lists a missing rubric: $indexed_rubric"
    done

# Every rubric body must carry the two required sections and stay copy-ready: a body with
# frontmatter cannot be moved into .spai/versioning.md as-is.
for rubric_body in skills/version-rubric/rubrics/*.md; do
  case "$(basename "$rubric_body")" in INDEX.md|_template.md|common.md) continue ;; esac
  require_text "$rubric_body" "## Decision Order"
  require_text "$rubric_body" "## Grade Definitions"
  if head -n 1 "$rubric_body" | grep -qx -- '---'; then
    fail "rubric body must not start with frontmatter: $rubric_body"
  fi
  if ! grep -q '^# ' "$rubric_body"; then
    fail "rubric body has no title: $rubric_body"
  fi
done

if find skills/version-rubric/rubrics -mindepth 1 -type d | grep -q .; then
  fail "rubric catalog must stay flat: INDEX.md carries the grouping, not directories"
fi

# Every rubric body names its consumer contract under one section title.
for rubric_body in skills/version-rubric/rubrics/*.md; do
  case "$(basename "$rubric_body")" in INDEX.md|_template.md|common.md) continue ;; esac
  require_text "$rubric_body" "## Public Interface"
done

# The catalog states which axis it grades on, because the default rubric uses another one.
require_text skills/version-rubric/rubrics/INDEX.md "SemVer consumer-compatibility axis"
require_text skills/version-rubric/SKILL.md "human-intervention axis"

# Ordered questions stop at the first match, so a rubric needs exactly three of them
# landing on patch, then minor, then major. A missing or reordered grade makes one
# grade unreachable no matter how the questions are worded.
for rubric_body in skills/version-rubric/rubrics/*.md; do
  case "$(basename "$rubric_body")" in INDEX.md|_template.md|common.md) continue ;; esac
  ordered_grades=$(awk '
    /^## Decision Order/ { p = 1; next }
    /^## / { p = 0 }
    p && /^[123]\./ {
      if (match($0, /`patch`/)) printf "patch "
      else if (match($0, /`minor`/)) printf "minor "
      else if (match($0, /`major`/)) printf "major "
      else printf "none "
    }
  ' "$rubric_body")
  [ "$ordered_grades" = "patch minor major " ] \
    || fail "decision order must be patch, minor, major in $rubric_body (found: $ordered_grades)"
done

# Hard Rules is the escalation section: every rule must name the grade it forces.
for rubric_body in skills/version-rubric/rubrics/*.md; do
  case "$(basename "$rubric_body")" in INDEX.md|_template.md|common.md) continue ;; esac
  awk -v file="$rubric_body" '
    /^## Hard Rules/ { p = 1; next }
    /^## / { p = 0 }
    p && /^>/ && !/`major`/ && !/`minor`/ { print file ": " $0; found = 1 }
    END { exit found ? 1 : 0 }
  ' "$rubric_body" || fail "escalation rule names no grade (see line above); move it to the section that owns it"
done

# rubric-scan reads the catalog and hands the write to version-rubric; it never writes.
require_text dist/claude-code-plugin/spai/skills/rubric-scan/SKILL.md "rubrics/INDEX.md"
require_text dist/claude-code-plugin/spai/skills/rubric-scan/SKILL.md "SPAI_RUBRIC_CATALOG"
require_text dist/claude-code-plugin/spai/skills/rubric-scan/SKILL.md "Read-only"
require_text dist/codex/.agents/skills/spai-rubric-scan/SKILL.md ".agents/skills/spai-version-rubric/rubrics"
if grep -F 'Write the file' dist/claude-code-plugin/spai/skills/rubric-scan/SKILL.md >/dev/null 2>&1; then
  fail "rubric-scan must not write the rubric file; version-rubric owns it"
fi
require_text dist/claude-code-plugin/spai/skills/version-rubric/SKILL.md "## Type Catalog"

require_text dist/codex/AGENTS.md "Scaffolded Procedures for AI Agents"
require_text dist/antigravity/GEMINI.md "Scaffolded Procedures for AI Agents"

require_file .claude-plugin/marketplace.json
require_text .claude-plugin/marketplace.json '"./dist/claude-code-plugin/spai"'

require_file "dist/claude-code-plugin/spai/.claude-plugin/plugin.json"
require_text "dist/claude-code-plugin/spai/.claude-plugin/plugin.json" '"name": "spai"'
require_text "dist/claude-code-plugin/spai/skills/develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/claude-code-plugin/spai/skills/github-release/SKILL.md" 'git push origin develop:main'

require_file "dist/claude-code-plugin/spai/hooks/hooks.json"
require_file "dist/claude-code-plugin/spai/hooks/guard-push.sh"
require_text "dist/claude-code-plugin/spai/hooks/hooks.json" '"PreToolUse"'
require_text "dist/claude-code-plugin/spai/hooks/hooks.json" 'CLAUDE_PLUGIN_ROOT'
require_text "dist/claude-code-plugin/spai/hooks/guard-push.sh" "spai:guard-push v1"
require_text "dist/claude-code-plugin/spai/skills/github-sync/SKILL.md" "spai:pre-push v1"

# Branch protection is optional and plan-gated. Both the applying skill and the diagnosing
# skill must read a 403 as "not available on this plan", never as an unprotected repository,
# and both must know the recorded choice key.
for protection_skill in github-sync spai-doctor; do
  require_text "dist/claude-code-plugin/spai/skills/$protection_skill/SKILL.md" "spai.branchProtection"
  require_text "dist/claude-code-plugin/spai/skills/$protection_skill/SKILL.md" "403"
  require_text "dist/codex/.agents/skills/$(prefixed_skill_name "$protection_skill")/SKILL.md" "spai.branchProtection"
done
require_text "dist/claude-code-plugin/spai/skills/spai-doctor/SKILL.md" "rulesets"
if ! grep -F "Optional: protect" install.sh >/dev/null 2>&1; then
  fail "install.sh must present branch protection as optional"
fi
require_text "dist/codex/.agents/skills/spai-github-sync/SKILL.md" "spai:pre-push v1"
require_text "dist/antigravity/.agents/skills/spai-github-sync/SKILL.md" "spai:pre-push v1"
require_text "dist/claude-code-plugin/spai/skills/project-setup/SKILL.md" "spai.githubProfile"
require_text "dist/claude-code-plugin/spai/skills/project-setup/SKILL.md" "Use after installing SPAI"
require_text "dist/codex/.agents/skills/spai-project-setup/SKILL.md" "SPAI_GITHUB_PROFILE"
require_text "dist/antigravity/.agents/skills/spai-project-setup/SKILL.md" "Do not use \`gh auth switch\`"

# The migration block grammar is a contract between three skills: github-release writes it,
# spai-update executes it, spai-doctor reports it. Drift in any one of them breaks the chain.
for migration_block in migration-auto migration-manual; do
  for migration_skill in github-release spai-update spai-doctor; do
    require_text "dist/claude-code-plugin/spai/skills/$migration_skill/SKILL.md" "spai:start $migration_block"
  done
done

# Markers are only markers on their own line. Every skill that reads them must say so,
# or a marker named in release-note prose gets counted as a block.
for migration_skill in github-release spai-update spai-doctor; do
  require_text "dist/claude-code-plugin/spai/skills/$migration_skill/SKILL.md" '^<!-- spai:'
done

if find dist -name "SKILL.*.md" ! -name "SKILL.md" | grep -q .; then
  fail "dist must contain only resolved SKILL.md files: solo-cli is the only flow"
fi

if grep -R 'team-pr' dist .claude-plugin manifest.tsv >/dev/null 2>&1; then
  fail "team-pr is not a supported flow; see docs/roadmap.md"
fi

if grep -R 'spai:owned\|spai:skill-start' dist >/dev/null 2>&1; then
  fail "dist must not carry ownership markers: namespacing replaced them"
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
