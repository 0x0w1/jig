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

require_same() {
  cmp -s "$1" "$2" || fail "files differ: $1 $2"
}

skill_title() {
  case "$1" in
    github-sync) printf '%s\n' "# GitHub Sync" ;;
    github-release) printf '%s\n' "# GitHub Release" ;;
    develop-task-flow) printf '%s\n' "# Develop Task Flow" ;;
    hotfix-flow) printf '%s\n' "# Hotfix Flow" ;;
    jig-setup) printf '%s\n' "# jig Setup" ;;
    jig-update) printf '%s\n' "# jig Update" ;;
    jig-doctor) printf '%s\n' "# jig Doctor" ;;
    repo-hygiene) printf '%s\n' "# Repo Hygiene" ;;
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
require_file scripts/update-skill-doc-digests.sh
if ! sh -n scripts/update-skill-doc-digests.sh; then
  fail "scripts/update-skill-doc-digests.sh has invalid shell syntax"
fi
require_text "dist/claude-code-plugin/jig/skills/jig-doctor/SKILL.md" "installation-inventory"
require_file "dist/claude-code-plugin/jig/skills/jig-doctor/scripts/inspect-claude-standalone.sh"
require_file "dist/codex/.agents/skills/jig-doctor/scripts/inspect-claude-standalone.sh"
require_file "dist/antigravity/.agents/skills/jig-doctor/scripts/inspect-claude-standalone.sh"
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" "Installation Inventory"
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" 'claude plugin update jig@jig --scope <scope>'
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" '~/.codex/AGENTS.md'
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" '~/.gemini/GEMINI.md'
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" "one current target never hides another"
require_file "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh"
require_file "dist/codex/.agents/skills/jig-update/scripts/update-claude-standalone.sh"
require_file "dist/antigravity/.agents/skills/jig-update/scripts/update-claude-standalone.sh"
require_text "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh" '.jig-provenance'
require_text "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh" '.jig-installation'
require_text "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh" 'ROLLBACK restoring standalone installation'
require_text "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh" 'unsafe payload path'
require_text "dist/claude-code-plugin/jig/skills/jig-update/scripts/update-claude-standalone.sh" 'unsafe symlink payload path'
require_text "dist/claude-code-plugin/jig/skills/jig-update/SKILL.md" '~/.claude/skills'
sh scripts/test-update-claude-standalone.sh
sh scripts/test-doctor-installation-inventory.sh
sh scripts/test-install-skill-aliases.sh
sh scripts/test-pre-push-manager.sh
sh scripts/test-docs-structure.sh
# The product name is jig everywhere the user types it.
require_text .claude-plugin/marketplace.json '"name": "jig"'
require_text .claude-plugin/marketplace.json '"./dist/claude-code-plugin/jig"'
obsolete_name=$(printf '\163\160\141\151')
if git grep -I -i "$obsolete_name" >/dev/null 2>&1; then
  fail "tracked files still contain the obsolete pre-rename product name"
fi

require_text install.sh "jig.githubProfile"
require_text install.sh "gh auth token"
require_text install.sh "GitHub profile is optional during installation"
require_text install.sh "repository settings sync is deferred to jig-setup"

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
require_text dist/codex/AGENTS.md "jig:start github-release-setup"
require_text dist/codex/AGENTS.md "jig:end github-release-setup"
require_text dist/codex/AGENTS.md "<!-- jig:version dev -->"

require_file dist/antigravity/GEMINI.md
require_text dist/antigravity/GEMINI.md "jig:start github-release-setup"
require_text dist/antigravity/GEMINI.md "jig:end github-release-setup"
require_text dist/antigravity/GEMINI.md "<!-- jig:version dev -->"

prefixed_skill_name() {
  case "$1" in
    jig-*) printf '%s' "$1" ;;
    *) printf 'jig-%s' "$1" ;;
  esac
}

if [ -e dist/claude-code ]; then
  fail "install.sh does not target claude-code: it ships the jig plugin under dist/claude-code-plugin instead"
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

  require_file "dist/claude-code-plugin/jig/skills/$skill/SKILL.md"
  require_text "dist/claude-code-plugin/jig/skills/$skill/SKILL.md" "$title"
done

require_text "dist/codex/.agents/skills/jig-develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/antigravity/.agents/skills/jig-develop-task-flow/SKILL.md" "Documentation Rules"
require_text "dist/codex/.agents/skills/jig-develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/antigravity/.agents/skills/jig-develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/codex/.agents/skills/jig-github-release/SKILL.md" "Develop-First Gate"
require_text "dist/codex/.agents/skills/jig-github-release/SKILL.md" 'git push origin develop:main'
require_text "dist/antigravity/.agents/skills/jig-github-release/SKILL.md" 'gh release create'

# The version rubric is a contract between four skills: version-rubric owns the file,
# github-release reads it, jig-setup delegates to it, jig-doctor reports it.
for rubric_skill in github-release jig-setup jig-doctor version-rubric develop-task-flow; do
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" ".jig/versioning.md"
  require_text "dist/codex/.agents/skills/$(prefixed_skill_name "$rubric_skill")/SKILL.md" ".jig/versioning.md"
done

for rubric_skill in github-release jig-doctor version-rubric; do
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## Decision Order"
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## Grade Definitions"
done

# The section titles went English while rubrics already written in Korean stay valid.
# Every skill that reads a rubric must still name the legacy spelling, or those files
# silently read as contract-broken.
for rubric_skill in github-release jig-doctor version-rubric; do
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## 판정 순서"
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## 등급 정의"
done
# The interface-path table is read by a command, so every skill that computes a floor
# from it must name the section under both spellings.
for rubric_skill in github-release version-rubric develop-task-flow; do
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## Interface Paths"
done
for rubric_skill in github-release version-rubric; do
  require_text "dist/claude-code-plugin/jig/skills/$rubric_skill/SKILL.md" "## 인터페이스 경로"
done

require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "> 기준:"
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "> Basis:"

# version-rubric ships the whole default rubric; the other skills must not copy it.
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "a fix inside what the project already does"
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "everything they already do keeps working"
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "must a human step in to keep using it"
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "## Hard Rules"
require_text "dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md" "## Version Format"

# The fallback inside github-release must stay identical to the default version-rubric
# writes, or a project grades differently depending on which skills happen to be installed.
require_text "dist/claude-code-plugin/jig/skills/github-release/SKILL.md" "must a human step in to keep using it"
require_text "dist/claude-code-plugin/jig/skills/github-release/SKILL.md" "changes when the agent speaks is at least"
require_text "dist/codex/.agents/skills/jig-version-rubric/SKILL.md" "JIG_VERSION_RUBRIC"
require_text "dist/antigravity/.agents/skills/jig-version-rubric/SKILL.md" "jig.versionRubric"

if grep -F 'must a human step in to keep using it' dist/claude-code-plugin/jig/skills/jig-setup/SKILL.md >/dev/null 2>&1; then
  fail "jig-setup must delegate to version-rubric, not duplicate the default rubric"
fi

# The rubric moved jig's own facts out of the distributed release skill. Keep them out.
for own_fact in 'scripts/validate-dist.sh' 'jig@jig' '0x0w1/jig' '--target'; do
  if grep -F "$own_fact" dist/claude-code-plugin/jig/skills/github-release/SKILL.md >/dev/null 2>&1; then
    fail "dist github-release leaks a jig-specific fact: $own_fact"
  fi
done

# This repository's own rubric is the normative source for its releases.
require_file .jig/versioning.md
require_text .jig/versioning.md "## 판정 순서"
require_text .jig/versioning.md "## 등급 정의"
require_text .jig/versioning.md "## 강경 규칙"
require_text .jig/versioning.md "sh scripts/validate-dist.sh"
# Every linked document exists in both languages and the pair links each other.
for doc_page in installation version-rubric versioning github-repository-settings roadmap; do
  require_file "docs/en/$doc_page.md"
  require_file "docs/ko/$doc_page.md"
  require_text "docs/en/$doc_page.md" "(../ko/$doc_page.md)"
  require_text "docs/ko/$doc_page.md" "(../en/$doc_page.md)"
done
require_file docs/en/index.md
require_file docs/ko/index.md
require_text docs/en/index.md "(../ko/index.md)"
require_text docs/ko/index.md "(../en/index.md)"
require_text README.ko.md "docs/ko/index.md"
require_text README.md "docs/en/index.md"
require_text README.ko.md "docs/ko/installation.md"
require_text README.md "docs/en/installation.md"

require_text docs/en/version-rubric.md "../../skills/version-rubric/rubrics/INDEX.md"
require_text README.md "docs/en/version-rubric.md"

if find docs -maxdepth 1 -type f -name '*.md' | grep -q .; then
  fail "docs root must contain only language directories"
fi
if find docs -type f -name '*.ko.md' | grep -q .; then
  fail "localized docs use docs/ko, not .ko.md suffixes"
fi
english_docs=$(cd docs/en && find . -type f -name '*.md' | LC_ALL=C sort)
korean_docs=$(cd docs/ko && find . -type f -name '*.md' | LC_ALL=C sort)
[ "$english_docs" = "$korean_docs" ] || fail "docs/en and docs/ko must have matching Markdown paths"

# README.md is the English canonical; README.ko.md is the Korean mirror. Each links the other,
# so a reader landing on either one can switch.
require_file README.ko.md
require_file resources/readme/jig-logo.png
require_file resources/readme/quick-start.svg
require_text README.md "resources/readme/jig-logo.png"
require_text README.md "resources/readme/quick-start.svg"
require_text README.ko.md "resources/readme/jig-logo.png"
require_text README.ko.md "resources/readme/quick-start.svg"
if grep -E 'docs/assets/|resources/branding/' README.md README.ko.md >/dev/null 2>&1; then
  fail "README files must reference published assets only from resources/readme"
fi
for readme_asset in resources/readme/*; do
  [ -f "$readme_asset" ] || continue
  require_text README.md "$readme_asset"
  require_text README.ko.md "$readme_asset"
done
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

# The diagram is read on light and dark GitHub themes; both palettes must stay defined.
require_text resources/readme/quick-start.svg "prefers-color-scheme: dark"
require_text resources/readme/quick-start.svg "role=\"img\""
require_text resources/readme/quick-start.svg "aria-label"

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
  require_file "dist/claude-code-plugin/jig/skills/version-rubric/$catalog_file"
  require_file "dist/codex/.agents/skills/jig-version-rubric/$catalog_file"
  require_file "dist/antigravity/.agents/skills/jig-version-rubric/$catalog_file"
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
# frontmatter cannot be moved into .jig/versioning.md as-is.
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
require_text dist/claude-code-plugin/jig/skills/rubric-scan/SKILL.md "rubrics/INDEX.md"
require_text dist/claude-code-plugin/jig/skills/rubric-scan/SKILL.md "JIG_RUBRIC_CATALOG"
require_text dist/claude-code-plugin/jig/skills/rubric-scan/SKILL.md "Read-only"
require_text dist/codex/.agents/skills/jig-rubric-scan/SKILL.md ".agents/skills/jig-version-rubric/rubrics"
if grep -F 'Write the file' dist/claude-code-plugin/jig/skills/rubric-scan/SKILL.md >/dev/null 2>&1; then
  fail "rubric-scan must not write the rubric file; version-rubric owns it"
fi
require_text dist/claude-code-plugin/jig/skills/version-rubric/SKILL.md "## Type Catalog"

require_text dist/codex/AGENTS.md "jig - repository procedures for AI agent CLIs"
require_text dist/antigravity/GEMINI.md "jig - repository procedures for AI agent CLIs"

require_file .claude-plugin/marketplace.json
require_text .claude-plugin/marketplace.json '"./dist/claude-code-plugin/jig"'

require_file "dist/claude-code-plugin/jig/.claude-plugin/plugin.json"
require_text "dist/claude-code-plugin/jig/.claude-plugin/plugin.json" '"name": "jig"'
require_text "dist/claude-code-plugin/jig/skills/develop-task-flow/SKILL.md" 'git merge --squash'
require_text "dist/claude-code-plugin/jig/skills/github-release/SKILL.md" 'git push origin develop:main'

require_file "dist/claude-code-plugin/jig/hooks/hooks.json"
require_file "dist/claude-code-plugin/jig/hooks/guard-push.sh"
require_text "dist/claude-code-plugin/jig/hooks/hooks.json" '"PreToolUse"'
require_text "dist/claude-code-plugin/jig/hooks/hooks.json" 'CLAUDE_PLUGIN_ROOT'
require_text "dist/claude-code-plugin/jig/hooks/guard-push.sh" "jig:guard-push v1"
require_file "dist/claude-code-plugin/jig/skills/github-sync/assets/pre-push"
require_file "dist/claude-code-plugin/jig/skills/github-sync/scripts/manage-pre-push.sh"
require_text "dist/claude-code-plugin/jig/skills/github-sync/assets/pre-push" "jig:pre-push v2"
require_text "dist/claude-code-plugin/jig/skills/github-sync/SKILL.md" "manage-pre-push.sh uninstall"
require_same "dist/claude-code-plugin/jig/skills/github-sync/SKILL.md" ".claude/skills/github-sync/SKILL.md"
require_same "dist/claude-code-plugin/jig/skills/github-sync/assets/pre-push" ".claude/skills/github-sync/assets/pre-push"
require_same "dist/claude-code-plugin/jig/skills/github-sync/scripts/manage-pre-push.sh" ".claude/skills/github-sync/scripts/manage-pre-push.sh"
require_same "dist/claude-code-plugin/jig/skills/jig-doctor/SKILL.md" ".claude/skills/jig-doctor/SKILL.md"

# Branch protection is optional and plan-gated. Both the applying skill and the diagnosing
# skill must read a 403 as "not available on this plan", never as an unprotected repository,
# and both must know the recorded choice key.
for protection_skill in github-sync jig-doctor; do
  require_text "dist/claude-code-plugin/jig/skills/$protection_skill/SKILL.md" "jig.branchProtection"
  require_text "dist/claude-code-plugin/jig/skills/$protection_skill/SKILL.md" "403"
  require_text "dist/codex/.agents/skills/$(prefixed_skill_name "$protection_skill")/SKILL.md" "jig.branchProtection"
done
require_text "dist/claude-code-plugin/jig/skills/jig-doctor/SKILL.md" "rulesets"
if ! grep -F "Optional: protect" install.sh >/dev/null 2>&1; then
  fail "install.sh must present branch protection as optional"
fi
for target in codex antigravity; do
  require_file "dist/$target/.agents/skills/jig-github-sync/assets/pre-push"
  require_file "dist/$target/.agents/skills/jig-github-sync/scripts/manage-pre-push.sh"
  require_text "dist/$target/.agents/skills/jig-github-sync/assets/pre-push" "jig:pre-push v2"
done
require_same "dist/codex/.agents/skills/jig-github-sync/SKILL.md" ".agents/skills/jig-github-sync/SKILL.md"
require_same "dist/codex/.agents/skills/jig-github-sync/assets/pre-push" ".agents/skills/jig-github-sync/assets/pre-push"
require_same "dist/codex/.agents/skills/jig-github-sync/scripts/manage-pre-push.sh" ".agents/skills/jig-github-sync/scripts/manage-pre-push.sh"
require_same "dist/codex/.agents/skills/jig-doctor/SKILL.md" ".agents/skills/jig-doctor/SKILL.md"
require_text "dist/claude-code-plugin/jig/skills/jig-setup/SKILL.md" "jig.githubProfile"
require_text "dist/claude-code-plugin/jig/skills/jig-setup/SKILL.md" "Use after installing jig"
require_text "dist/codex/.agents/skills/jig-setup/SKILL.md" "JIG_GITHUB_PROFILE"
require_text "dist/antigravity/.agents/skills/jig-setup/SKILL.md" "Do not use \`gh auth switch\`"

# The migration block grammar is a contract between three skills: github-release writes it,
# jig-update executes it, jig-doctor reports it. Drift in any one of them breaks the chain.
for migration_block in migration-auto migration-manual; do
  for migration_skill in github-release jig-update jig-doctor; do
    require_text "dist/claude-code-plugin/jig/skills/$migration_skill/SKILL.md" "jig:start $migration_block"
  done
done

# Markers are only markers on their own line. Every skill that reads them must say so,
# or a marker named in release-note prose gets counted as a block.
for migration_skill in github-release jig-update jig-doctor; do
  require_text "dist/claude-code-plugin/jig/skills/$migration_skill/SKILL.md" '^<!-- jig:'
done

if find dist -name "SKILL.*.md" ! -name "SKILL.md" | grep -q .; then
  fail "dist must contain only resolved SKILL.md files: solo-cli is the only flow"
fi

if grep -R 'team-pr' dist .claude-plugin manifest.tsv >/dev/null 2>&1; then
  fail "team-pr is not a supported flow; see docs/en/roadmap.md"
fi

if grep -R 'jig:owned\|jig:skill-start' dist >/dev/null 2>&1; then
  fail "dist must not carry ownership markers: namespacing replaced them"
fi

if grep -R 'agent-release-skill' dist >/dev/null 2>&1; then
  fail "dist contains forbidden agent-release-skill string"
fi

# A release never merges main back into develop. The one legitimate back-merge is
# hotfix-flow step 8, which restores the fast-forward invariant a hotfix breaks, so
# that skill's payload is the only place the term may appear.
if grep -R -E 'back-merge|backmerge|백머지' dist \
    --exclude-dir=hotfix-flow --exclude-dir=jig-hotfix-flow >/dev/null 2>&1; then
  fail "dist contains forbidden back-merge text outside hotfix-flow"
fi

if grep -R 'release-drafter/release-drafter' dist >/dev/null 2>&1; then
  fail "dist contains a release-drafter workflow reference"
fi

if ! grep -R 'jig' dist >/dev/null 2>&1; then
  fail "dist does not contain jig"
fi

echo "dist validation ok"
