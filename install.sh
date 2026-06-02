#!/usr/bin/env sh
set -eu

TARGET="all"
SCOPE="project"
DRY_RUN=0
FORCE=0
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/0x0w1/spai/main}"
INSTALLED_FILES=""
SYNCED_LABELS=""
VERIFIED_LABELS=""
SYNCED_REPOSITORY_SETTINGS=""
SYNCED_BRANCH_PROTECTIONS=""
VERIFIED_BRANCH_PROTECTIONS=""

print_help() {
  cat <<'EOF'
SPAI - Scaffolded Procedures for AI Agents

Usage:
  sh install.sh [--target <target>] [--scope <scope>] [--dry-run] [--force]

Targets:
  codex
  claude-code
  cursor
  gemini-cli
  opencode
  all

Scopes:
  project
  global

Defaults:
  --target all
  --scope project

Examples:
  wget -qO- https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target codex --scope project

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target claude-code --scope project

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target all --scope project

Environment:
  REPO_RAW_URL=https://raw.githubusercontent.com/my-org/spai/main sh install.sh

Project scope also installs:
  .github/drafter-config.yaml
  .github/workflows/drafter.yaml

Project scope also syncs these GitHub labels when gh is available:
  patch, minor, major, enhancement, fix, chore

Project scope also syncs GitHub repository settings when gh is available:
  general: Automatically delete head branches
  branches: main and develop protection rules

Target-specific project installs:
  codex: .agents/skills/* plus AGENTS.md
  claude-code: .claude/skills/* plus CLAUDE.md
  cursor: .cursor/rules/*.mdc
  gemini-cli: GEMINI.md
  opencode: AGENTS.md
EOF
}

log() {
  printf 'SPAI [info] %s\n' "$*"
}

warn() {
  printf 'SPAI [warn] %s\n' "$*" >&2
}

error() {
  printf 'SPAI [error] %s\n' "$*" >&2
  exit 1
}

print_list() {
  list_title="$1"
  list_items="$2"

  [ -n "$list_items" ] || return 0
  printf '\nSPAI [summary] %s\n' "$list_title"
  printf '%s\n' "$list_items" | sed '/^$/d; s/^/  - /'
}

need_downloader() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    return 0
  fi
  error "curl or wget is required."
}

download_file() {
  download_url="$1"
  download_destination="$2"
  download_parent=$(dirname "$download_destination")
  mkdir -p "$download_parent"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$download_url" -o "$download_destination"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$download_destination" "$download_url"
  else
    error "download failed: curl or wget is not available."
  fi
}

record_installed() {
  INSTALLED_FILES="${INSTALLED_FILES}
$1"
}

record_label() {
  SYNCED_LABELS="${SYNCED_LABELS}
$1"
}

record_verified_label() {
  VERIFIED_LABELS="${VERIFIED_LABELS}
$1"
}

record_repository_setting() {
  SYNCED_REPOSITORY_SETTINGS="${SYNCED_REPOSITORY_SETTINGS}
$1"
}

record_branch_protection() {
  SYNCED_BRANCH_PROTECTIONS="${SYNCED_BRANCH_PROTECTIONS}
$1"
}

record_verified_branch_protection() {
  VERIFIED_BRANCH_PROTECTIONS="${VERIFIED_BRANCH_PROTECTIONS}
$1"
}

copy_file_with_backup() {
  copy_source_url="$1"
  copy_destination="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would copy: $copy_source_url -> $copy_destination"
    return 0
  fi

  copy_tmp=$(mktemp)
  download_file "$copy_source_url" "$copy_tmp"
  mkdir -p "$(dirname "$copy_destination")"

  if [ ! -f "$copy_destination" ]; then
    cp "$copy_tmp" "$copy_destination"
    record_installed "$copy_destination"
    rm -f "$copy_tmp"
    return 0
  fi

  if cmp -s "$copy_tmp" "$copy_destination"; then
    log "Skipped unchanged file: $copy_destination"
    rm -f "$copy_tmp"
    return 0
  fi

  cp "$copy_destination" "$copy_destination.bak"
  cp "$copy_tmp" "$copy_destination"
  record_installed "$copy_destination"
  rm -f "$copy_tmp"
}

extract_managed_block() {
  extract_source="$1"
  extract_block="$2"
  extract_start_marker="$3"
  extract_end_marker="$4"

  if grep -F "$extract_start_marker" "$extract_source" >/dev/null 2>&1 && grep -F "$extract_end_marker" "$extract_source" >/dev/null 2>&1; then
    awk -v start="$extract_start_marker" -v end="$extract_end_marker" '
      index($0, start) { printing = 1 }
      printing { print }
      index($0, end) { printing = 0 }
    ' "$extract_source" > "$extract_block"
  else
    cp "$extract_source" "$extract_block"
  fi
}

install_managed_block() {
  managed_source_url="$1"
  managed_destination="$2"
  managed_start_marker="$3"
  managed_end_marker="$4"

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would install managed block: $managed_source_url -> $managed_destination"
    return 0
  fi

  managed_source_tmp=$(mktemp)
  managed_block_tmp=$(mktemp)
  managed_new_tmp=$(mktemp)
  download_file "$managed_source_url" "$managed_source_tmp"
  mkdir -p "$(dirname "$managed_destination")"
  extract_managed_block "$managed_source_tmp" "$managed_block_tmp" "$managed_start_marker" "$managed_end_marker"

  if [ ! -f "$managed_destination" ]; then
    cp "$managed_source_tmp" "$managed_destination"
    record_installed "$managed_destination"
    rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
    return 0
  fi

  if grep -F "$managed_start_marker" "$managed_destination" >/dev/null 2>&1 && grep -F "$managed_end_marker" "$managed_destination" >/dev/null 2>&1; then
    awk -v start="$managed_start_marker" -v end="$managed_end_marker" -v block="$managed_block_tmp" '
      BEGIN {
        replacement = ""
        while ((getline line < block) > 0) {
          replacement = replacement line ORS
        }
        close(block)
      }
      index($0, start) {
        printf "%s", replacement
        inside = 1
        next
      }
      inside && index($0, end) {
        inside = 0
        next
      }
      !inside { print }
    ' "$managed_destination" > "$managed_new_tmp"
  else
    cp "$managed_destination" "$managed_new_tmp"
    printf '\n' >> "$managed_new_tmp"
    cat "$managed_source_tmp" >> "$managed_new_tmp"
  fi

  if cmp -s "$managed_new_tmp" "$managed_destination"; then
    log "Skipped unchanged managed block: $managed_destination"
    rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
    return 0
  fi

  cp "$managed_destination" "$managed_destination.bak"
  cp "$managed_new_tmp" "$managed_destination"
  record_installed "$managed_destination"
  rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
}

install_project_github_files() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  copy_file_with_backup "$REPO_RAW_URL/dist/github/drafter-config.yaml" "./.github/drafter-config.yaml"
  copy_file_with_backup "$REPO_RAW_URL/dist/github/workflows/drafter.yaml" "./.github/workflows/drafter.yaml"
}

project_github_context_ready() {
  context_action="$1"

  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI check failed: gh is not installed. Skipping $context_action."
    return 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI check failed: gh authentication is not available. Skipping $context_action."
    return 1
  fi
  log "GitHub CLI check passed"

  if ! command -v git >/dev/null 2>&1; then
    log "Git repository check passed: git is not installed, so $context_action was skipped."
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Git repository check passed: no .git repository found, so $context_action was skipped."
    return 1
  fi
  log "Git repository check passed"

  if ! gh repo view >/dev/null 2>&1; then
    warn "GitHub repository check failed: current directory is not connected to a GitHub repository. Skipping $context_action."
    return 1
  fi
  log "GitHub repository check passed"

  return 0
}

github_repo_slug() {
  gh repo view --json nameWithOwner --jq .nameWithOwner
}

ensure_github_label() {
  label_name="$1"
  label_color="$2"
  label_description="$3"

  if github_label_exists "$label_name"; then
    gh label edit "$label_name" --color "$label_color" --description "$label_description" >/dev/null
    log "GitHub label updated: $label_name"
    record_label "$label_name (updated)"
    return 0
  fi

  gh label create "$label_name" --color "$label_color" --description "$label_description" >/dev/null
  log "GitHub label created: $label_name"
  record_label "$label_name (created)"
}

github_label_exists() {
  label_name="$1"

  gh label list --limit 1000 | awk -F '\t' -v name="$label_name" '
    $1 == name { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

sync_github_labels() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would check GitHub CLI setup"
    log "[dry-run] Would check git repository"
    log "[dry-run] Would sync GitHub labels: patch, minor, major, enhancement, fix, chore"
    log "[dry-run] Would verify GitHub labels: patch, minor, major, enhancement, fix, chore"
    return 0
  fi

  if ! project_github_context_ready "GitHub label sync"; then
    return 0
  fi

  ensure_github_label "patch" "0E8A16" "하위 호환 버그 수정 또는 내부 변경"
  ensure_github_label "minor" "1D76DB" "하위 호환 신규 기능"
  ensure_github_label "major" "B60205" "호환성을 깨는(breaking) 변경"
  ensure_github_label "enhancement" "A2EEEF" "사용자에게 보이는 신규 기능 또는 개선"
  ensure_github_label "fix" "FBCA04" "버그, 회귀(regression), 또는 보안 수정"
  ensure_github_label "chore" "CFD3D7" "의존성, 툴링, 리팩터링, 문서"

  verify_github_labels
}

verify_label_in_file() {
  verify_file="$1"
  verify_name="$2"
  verify_color="#$3"

  awk -F '\t' -v name="$verify_name" -v color="$verify_color" '
    $1 == name {
      found = 1
      actual = toupper($3)
      expected = toupper(color)
    }
    END {
      if (!found) {
        exit 1
      }
      if (actual != expected) {
        exit 2
      }
    }
  ' "$verify_file"
}

verify_github_label() {
  verify_file="$1"
  verify_name="$2"
  verify_color="$3"

  if ! verify_label_in_file "$verify_file" "$verify_name" "$verify_color"; then
    error "GitHub label verification failed: $verify_name"
  fi
  record_verified_label "$verify_name"
}

verify_github_labels() {
  labels_tmp=$(mktemp)
  gh label list --limit 1000 > "$labels_tmp"

  verify_github_label "$labels_tmp" "patch" "0E8A16"
  verify_github_label "$labels_tmp" "minor" "1D76DB"
  verify_github_label "$labels_tmp" "major" "B60205"
  verify_github_label "$labels_tmp" "enhancement" "A2EEEF"
  verify_github_label "$labels_tmp" "fix" "FBCA04"
  verify_github_label "$labels_tmp" "chore" "CFD3D7"

  rm -f "$labels_tmp"
}

github_branch_exists() {
  repo_slug="$1"
  branch_name="$2"
  gh api "repos/$repo_slug/branches/$branch_name" >/dev/null 2>&1
}

release_drafter_check_available() {
  repo_slug="$1"
  main_sha=$(gh api "repos/$repo_slug/branches/main" --jq .commit.sha 2>/dev/null || true)
  [ -n "$main_sha" ] || return 1

  gh api "repos/$repo_slug/commits/$main_sha/check-runs?per_page=100" --jq '.check_runs[].name' 2>/dev/null |
    grep -Fx "update_release_draft" >/dev/null 2>&1
}

write_branch_protection_payload() {
  protection_branch="$1"
  protection_repo="$2"
  protection_payload="$3"

  if [ "$protection_branch" = "main" ] && release_drafter_check_available "$protection_repo"; then
    cat > "$protection_payload" <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "update_release_draft"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF
    return 0
  fi

  cat > "$protection_payload" <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF
}

sync_repository_general_settings() {
  repo_slug="$1"

  if gh api -X PATCH "repos/$repo_slug" -F delete_branch_on_merge=true >/dev/null 2>&1; then
    log "GitHub repository setting enabled: Automatically delete head branches"
    record_repository_setting "Automatically delete head branches (enabled)"
  else
    warn "GitHub repository setting failed: Automatically delete head branches. Check repository admin permission."
    return 0
  fi

  delete_branch_on_merge=$(gh api "repos/$repo_slug" --jq .delete_branch_on_merge 2>/dev/null || printf 'unknown')
  if [ "$delete_branch_on_merge" = "true" ]; then
    record_repository_setting "Automatically delete head branches (verified)"
  else
    warn "GitHub repository setting verification failed: Automatically delete head branches"
  fi
}

sync_branch_protection() {
  repo_slug="$1"
  protection_branch="$2"

  if ! github_branch_exists "$repo_slug" "$protection_branch"; then
    warn "GitHub branch protection skipped: $protection_branch does not exist on GitHub."
    return 0
  fi

  protection_payload=$(mktemp)
  write_branch_protection_payload "$protection_branch" "$repo_slug" "$protection_payload"

  if gh api -X PUT "repos/$repo_slug/branches/$protection_branch/protection" --input "$protection_payload" >/dev/null 2>&1; then
    log "GitHub branch protection synced: $protection_branch"
    if [ "$protection_branch" = "main" ] && grep -F "update_release_draft" "$protection_payload" >/dev/null 2>&1; then
      record_branch_protection "$protection_branch (PR required, no force push, no deletion, conversations required, update_release_draft required)"
    else
      record_branch_protection "$protection_branch (PR required, no force push, no deletion, conversations required)"
    fi
  else
    warn "GitHub branch protection failed: $protection_branch. Check repository plan and admin permission."
    rm -f "$protection_payload"
    return 0
  fi

  rm -f "$protection_payload"
  verify_branch_protection "$repo_slug" "$protection_branch"
}

verify_branch_protection() {
  repo_slug="$1"
  protection_branch="$2"

  pr_required=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .required_pull_request_reviews == null then "false" else "true" end' 2>/dev/null || printf 'false')
  allow_force_pushes=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .allow_force_pushes.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')
  allow_deletions=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .allow_deletions.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')
  conversation_required=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .required_conversation_resolution.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')

  if [ "$pr_required" = "true" ] &&
    [ "$allow_force_pushes" = "false" ] &&
    [ "$allow_deletions" = "false" ] &&
    [ "$conversation_required" = "true" ]; then
    record_verified_branch_protection "$protection_branch"
    return 0
  fi

  warn "GitHub branch protection verification failed: $protection_branch"
}

sync_github_repository_settings() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would enable GitHub repository setting: Automatically delete head branches"
    log "[dry-run] Would sync GitHub branch protection: main"
    log "[dry-run] Would sync GitHub branch protection: develop"
    log "[dry-run] Would verify GitHub branch protection: main, develop"
    return 0
  fi

  if ! project_github_context_ready "GitHub repository settings sync"; then
    return 0
  fi

  repo_slug=$(github_repo_slug)
  sync_repository_general_settings "$repo_slug"
  sync_branch_protection "$repo_slug" "main"
  sync_branch_protection "$repo_slug" "develop"
}

install_claude_code() {
  if [ "$SCOPE" = "project" ]; then
    memory_destination="./CLAUDE.md"
    skill_base="./.claude/skills"
  else
    memory_destination="$HOME/.claude/CLAUDE.md"
    skill_base="$HOME/.claude/skills"
  fi
  install_managed_block "$REPO_RAW_URL/dist/claude-code/CLAUDE.md" "$memory_destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/.claude/skills/github-sync/SKILL.md" "$skill_base/github-sync/SKILL.md"
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/.claude/skills/github-release/SKILL.md" "$skill_base/github-release/SKILL.md"
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/.claude/skills/develop-task-flow/SKILL.md" "$skill_base/develop-task-flow/SKILL.md"
}

install_codex() {
  if [ "$SCOPE" = "project" ]; then
    destination="./AGENTS.md"
    skill_base="./.agents/skills"
  else
    destination="$HOME/.codex/AGENTS.md"
    skill_base="$HOME/.agents/skills"
  fi
  copy_file_with_backup "$REPO_RAW_URL/dist/codex/.agents/skills/github-sync/SKILL.md" "$skill_base/github-sync/SKILL.md"
  copy_file_with_backup "$REPO_RAW_URL/dist/codex/.agents/skills/github-release/SKILL.md" "$skill_base/github-release/SKILL.md"
  copy_file_with_backup "$REPO_RAW_URL/dist/codex/.agents/skills/develop-task-flow/SKILL.md" "$skill_base/develop-task-flow/SKILL.md"
  install_managed_block "$REPO_RAW_URL/dist/codex/AGENTS.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_cursor() {
  if [ "$SCOPE" = "global" ]; then
    error "The cursor target currently supports project scope only. Use --scope project."
  fi
  copy_file_with_backup "$REPO_RAW_URL/dist/cursor/.cursor/rules/github-sync.mdc" "./.cursor/rules/github-sync.mdc"
  copy_file_with_backup "$REPO_RAW_URL/dist/cursor/.cursor/rules/github-release.mdc" "./.cursor/rules/github-release.mdc"
  copy_file_with_backup "$REPO_RAW_URL/dist/cursor/.cursor/rules/develop-task-flow.mdc" "./.cursor/rules/develop-task-flow.mdc"
}

install_gemini_cli() {
  if [ "$SCOPE" = "project" ]; then
    destination="./GEMINI.md"
  else
    destination="$HOME/.gemini/GEMINI.md"
  fi
  install_managed_block "$REPO_RAW_URL/dist/gemini-cli/GEMINI.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_opencode() {
  if [ "$SCOPE" = "project" ]; then
    destination="./AGENTS.md"
  else
    destination="$HOME/.config/opencode/AGENTS.md"
  fi
  install_managed_block "$REPO_RAW_URL/dist/opencode/AGENTS.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_target() {
  case "$1" in
    claude-code) install_claude_code ;;
    codex) install_codex ;;
    cursor) install_cursor ;;
    gemini-cli) install_gemini_cli ;;
    opencode) install_opencode ;;
    *) error "unsupported target: $1" ;;
  esac
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target)
        shift
        [ "$#" -gt 0 ] || error "--target requires a value"
        TARGET="$1"
        ;;
      --scope)
        shift
        [ "$#" -gt 0 ] || error "--scope requires a value"
        SCOPE="$1"
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --force)
        FORCE=1
        ;;
      --help|-h)
        print_help
        exit 0
        ;;
      *)
        error "unknown option: $1"
        ;;
    esac
    shift
  done

  case "$TARGET" in
    claude-code|codex|cursor|gemini-cli|opencode|all) ;;
    *) error "unsupported target: $TARGET" ;;
  esac

  case "$SCOPE" in
    project|global) ;;
    *) error "unsupported scope: $SCOPE" ;;
  esac

  need_downloader

  if [ "$TARGET" = "all" ]; then
    install_target codex
    install_target claude-code
    if [ "$SCOPE" = "global" ]; then
      warn "Skipping cursor: the cursor target currently supports project scope only."
    else
      install_target cursor
    fi
    install_target gemini-cli
    install_target opencode
  else
    install_target "$TARGET"
  fi

  install_project_github_files
  sync_github_labels
  sync_github_repository_settings

  log "Installation complete"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run only; no files were modified."
  elif [ -n "$INSTALLED_FILES" ]; then
    print_list "Installed files" "$INSTALLED_FILES"
  else
    log "No file changes"
  fi

  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub labels" "$SYNCED_LABELS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub labels" "$VERIFIED_LABELS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub repository settings" "$SYNCED_REPOSITORY_SETTINGS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub branch protections" "$SYNCED_BRANCH_PROTECTIONS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub branch protections" "$VERIFIED_BRANCH_PROTECTIONS"
}

main "$@"
