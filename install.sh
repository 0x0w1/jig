#!/usr/bin/env sh
set -eu

TARGET="all"
SCOPE="project"
DRY_RUN=0
FORCE=0
GITHUB_ACCOUNT="${SPAI_GITHUB_ACCOUNT:-}"
GITHUB_HOST="${SPAI_GITHUB_HOST:-github.com}"
CONFIGURE_GIT_USER="${SPAI_CONFIGURE_GIT_USER:-0}"
GIT_USER_NAME="${SPAI_GIT_USER_NAME:-}"
GIT_USER_EMAIL="${SPAI_GIT_USER_EMAIL:-}"
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/0x0w1/spai/main}"
INSTALLED_FILES=""
SYNCED_LABELS=""
DELETED_LABELS=""
VERIFIED_LABELS=""
VERIFIED_GITHUB_ACCOUNT=""
SYNCED_GIT_CONFIG=""
SYNCED_REPOSITORY_SETTINGS=""
SYNCED_BRANCHES=""
VERIFIED_BRANCHES=""
SYNCED_BRANCH_PROTECTIONS=""
VERIFIED_BRANCH_PROTECTIONS=""

print_help() {
  cat <<'EOF'
SPAI - Scaffolded Procedures for AI Agents

Usage:
  sh install.sh [--target <target>] [--scope <scope>] [--github-account <account>] [--configure-git-user] [--dry-run] [--force]

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
    | sh -s -- --target codex --scope project --github-account 0x0w1

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target claude-code --scope project --github-account 0x0w1

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target all --scope project --github-account 0x0w1

Environment:
  REPO_RAW_URL=https://raw.githubusercontent.com/my-org/spai/main SPAI_GITHUB_ACCOUNT=0x0w1 sh install.sh
  SPAI_GITHUB_ACCOUNT=0x0w1 sh install.sh --target all --scope project
  SPAI_GITHUB_HOST=github.example.com SPAI_GITHUB_ACCOUNT=monalisa sh install.sh --target all --scope project
  SPAI_GIT_USER_NAME="Mona Lisa" SPAI_GIT_USER_EMAIL=monalisa@example.com sh install.sh --target all --scope project --github-account monalisa

GitHub account:
  Project scope requires --github-account <account> or SPAI_GITHUB_ACCOUNT.
  Use --github-host <host> or SPAI_GITHUB_HOST for GitHub Enterprise hosts.
  The installer logs in with gh when needed, then switches gh to that account before GitHub label, branch, and repository settings sync.

Local git user:
  Use --configure-git-user to prompt for local user.name and user.email.
  Use --git-user-name and --git-user-email, or SPAI_GIT_USER_NAME and SPAI_GIT_USER_EMAIL, to set them non-interactively.

Project scope also installs:
  .github/drafter-config.yaml
  .github/workflows/drafter.yaml

Project scope also keeps exactly these GitHub labels when gh is available:
  patch, minor, major, enhancement, fix, chore
  It creates or updates these labels and deletes all other labels.

Project scope also syncs GitHub repository settings when gh is available:
  account: selected by --github-account or SPAI_GITHUB_ACCOUNT
  general: Automatically delete head branches
  branches: develop creation plus main and develop protection rules

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

prompt_tty() {
  prompt_message="$1"

  if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
    error "interactive input requires a terminal. Pass --git-user-name and --git-user-email instead."
  fi

  printf '%s' "$prompt_message" >/dev/tty
  IFS= read -r prompt_answer </dev/tty || error "failed to read interactive input."
  printf '%s\n' "$prompt_answer"
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

record_deleted_label() {
  DELETED_LABELS="${DELETED_LABELS}
$1"
}

record_verified_label() {
  VERIFIED_LABELS="${VERIFIED_LABELS}
$1"
}

record_verified_github_account() {
  VERIFIED_GITHUB_ACCOUNT="${VERIFIED_GITHUB_ACCOUNT}
$1"
}

record_git_config() {
  SYNCED_GIT_CONFIG="${SYNCED_GIT_CONFIG}
$1"
}

record_repository_setting() {
  SYNCED_REPOSITORY_SETTINGS="${SYNCED_REPOSITORY_SETTINGS}
$1"
}

record_branch() {
  SYNCED_BRANCHES="${SYNCED_BRANCHES}
$1"
}

record_verified_branch() {
  VERIFIED_BRANCHES="${VERIFIED_BRANCHES}
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

sync_local_git_user_config() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$CONFIGURE_GIT_USER" != "1" ] && [ -z "$GIT_USER_NAME" ] && [ -z "$GIT_USER_EMAIL" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would configure local git user.name/user.email"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    error "git is required to configure local user.name/user.email."
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error "local git user config requires running inside a git repository."
  fi

  current_git_user_name=$(git config --local --get user.name 2>/dev/null || true)
  current_git_user_email=$(git config --local --get user.email 2>/dev/null || true)
  log "Current local git user.name: ${current_git_user_name:-unset}"
  log "Current local git user.email: ${current_git_user_email:-unset}"

  if [ -z "$GIT_USER_NAME" ]; then
    GIT_USER_NAME=$(prompt_tty "Local git user.name: ")
  fi

  if [ -z "$GIT_USER_EMAIL" ]; then
    GIT_USER_EMAIL=$(prompt_tty "Local git user.email: ")
  fi

  [ -n "$GIT_USER_NAME" ] || error "local git user.name is required."
  [ -n "$GIT_USER_EMAIL" ] || error "local git user.email is required."

  git config --local user.name "$GIT_USER_NAME"
  git config --local user.email "$GIT_USER_EMAIL"
  log "Local git user config updated"
  record_git_config "user.name=$GIT_USER_NAME"
  record_git_config "user.email=$GIT_USER_EMAIL"
}

github_active_account() {
  gh auth status --active --hostname "$GITHUB_HOST" --json hosts --jq '.hosts | to_entries[0].value[0].login' 2>/dev/null || true
}

ensure_github_login() {
  if gh auth switch --hostname "$GITHUB_HOST" --user "$GITHUB_ACCOUNT" >/dev/null 2>&1; then
    return 0
  fi

  warn "GitHub CLI account is not available yet: $GITHUB_ACCOUNT@$GITHUB_HOST"
  log "Starting GitHub CLI login for $GITHUB_HOST"
  if ! gh auth login --hostname "$GITHUB_HOST"; then
    error "GitHub CLI login failed for $GITHUB_HOST."
  fi

  if ! gh auth switch --hostname "$GITHUB_HOST" --user "$GITHUB_ACCOUNT" >/dev/null 2>&1; then
    error "GitHub account selection failed after login: $GITHUB_ACCOUNT@$GITHUB_HOST"
  fi
}

select_github_account() {
  context_action="$1"

  if [ -n "$VERIFIED_GITHUB_ACCOUNT" ]; then
    return 0
  fi

  if [ -z "$GITHUB_ACCOUNT" ]; then
    error "GitHub account is required for $context_action. Pass --github-account <account> or set SPAI_GITHUB_ACCOUNT."
  fi

  ensure_github_login

  active_account=$(github_active_account)
  if [ "$active_account" != "$GITHUB_ACCOUNT" ]; then
    error "GitHub account verification failed: expected $GITHUB_ACCOUNT on $GITHUB_HOST, got ${active_account:-unknown}."
  fi

  log "GitHub CLI account selected: $GITHUB_ACCOUNT@$GITHUB_HOST"
  record_verified_github_account "$GITHUB_ACCOUNT@$GITHUB_HOST"
}

project_github_context_ready() {
  context_action="$1"

  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI check failed: gh is not installed. Skipping $context_action."
    return 1
  fi

  select_github_account "$context_action"
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

is_standard_github_label() {
  case "$1" in
    patch|minor|major|enhancement|fix|chore) return 0 ;;
    *) return 1 ;;
  esac
}

delete_nonstandard_github_labels() {
  labels_tmp=$(mktemp)
  label_names_tmp=$(mktemp)

  gh label list --limit 1000 > "$labels_tmp"
  awk -F '\t' '{ print $1 }' "$labels_tmp" > "$label_names_tmp"

  while IFS= read -r label_name; do
    [ -n "$label_name" ] || continue
    if is_standard_github_label "$label_name"; then
      continue
    fi

    if gh label delete "$label_name" --yes >/dev/null; then
      log "GitHub label deleted: $label_name"
      record_deleted_label "$label_name"
    else
      rm -f "$labels_tmp" "$label_names_tmp"
      error "GitHub label deletion failed: $label_name"
    fi
  done < "$label_names_tmp"

  rm -f "$labels_tmp" "$label_names_tmp"
}

sync_github_labels() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would use GitHub CLI account: $GITHUB_ACCOUNT@$GITHUB_HOST"
    log "[dry-run] Would check GitHub CLI setup"
    log "[dry-run] Would check git repository"
    log "[dry-run] Would sync GitHub labels: patch, minor, major, enhancement, fix, chore"
    log "[dry-run] Would delete GitHub labels outside the standard six"
    log "[dry-run] Would verify exactly these GitHub labels remain: patch, minor, major, enhancement, fix, chore"
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

  delete_nonstandard_github_labels
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

verify_only_standard_github_labels() {
  verify_file="$1"
  verify_names_tmp=$(mktemp)

  awk -F '\t' '{ print $1 }' "$verify_file" > "$verify_names_tmp"
  while IFS= read -r verify_name; do
    [ -n "$verify_name" ] || continue
    if ! is_standard_github_label "$verify_name"; then
      rm -f "$verify_names_tmp"
      error "GitHub label verification failed: unexpected label remains: $verify_name"
    fi
  done < "$verify_names_tmp"

  rm -f "$verify_names_tmp"
  record_verified_label "only standard labels remain"
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
  verify_only_standard_github_labels "$labels_tmp"

  rm -f "$labels_tmp"
}

github_branch_exists() {
  repo_slug="$1"
  branch_name="$2"
  gh api "repos/$repo_slug/branches/$branch_name" >/dev/null 2>&1
}

github_branch_sha() {
  repo_slug="$1"
  branch_name="$2"
  gh api "repos/$repo_slug/branches/$branch_name" --jq .commit.sha 2>/dev/null || true
}

ensure_github_branch() {
  repo_slug="$1"
  branch_name="$2"
  source_branch="$3"

  if github_branch_exists "$repo_slug" "$branch_name"; then
    log "GitHub branch exists: $branch_name"
    record_verified_branch "$branch_name (exists)"
    return 0
  fi

  source_sha=$(github_branch_sha "$repo_slug" "$source_branch")
  if [ -z "$source_sha" ]; then
    warn "GitHub branch creation skipped: source branch $source_branch does not exist."
    return 0
  fi

  if gh api -X POST "repos/$repo_slug/git/refs" -f ref="refs/heads/$branch_name" -f sha="$source_sha" >/dev/null 2>&1; then
    log "GitHub branch created: $branch_name from $source_branch"
    record_branch "$branch_name (created from $source_branch)"
  elif github_branch_exists "$repo_slug" "$branch_name"; then
    log "GitHub branch exists: $branch_name"
    record_verified_branch "$branch_name (exists)"
    return 0
  else
    warn "GitHub branch creation failed: $branch_name from $source_branch. Check repository admin permission."
    return 0
  fi

  if github_branch_exists "$repo_slug" "$branch_name"; then
    record_verified_branch "$branch_name"
  else
    warn "GitHub branch verification failed: $branch_name"
  fi
}

write_branch_protection_payload() {
  protection_payload="$3"

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
    log "GitHub classic branch protection synced: $protection_branch"
    record_branch_protection "$protection_branch (classic, PR required, status checks off, no force push, no deletion, conversations required)"
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
  status_checks_required=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .required_status_checks == null then "false" else "true" end' 2>/dev/null || printf 'unknown')
  allow_force_pushes=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .allow_force_pushes.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')
  allow_deletions=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .allow_deletions.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')
  conversation_required=$(gh api "repos/$repo_slug/branches/$protection_branch/protection" --jq 'if .required_conversation_resolution.enabled == true then "true" else "false" end' 2>/dev/null || printf 'unknown')

  if [ "$pr_required" = "true" ] &&
    [ "$status_checks_required" = "false" ] &&
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
    log "[dry-run] Would use GitHub CLI account: $GITHUB_ACCOUNT@$GITHUB_HOST"
    log "[dry-run] Would enable GitHub repository setting: Automatically delete head branches"
    log "[dry-run] Would ensure GitHub branch exists: develop (created from main if missing)"
    log "[dry-run] Would sync GitHub classic branch protection: main"
    log "[dry-run] Would sync GitHub classic branch protection: develop"
    log "[dry-run] Would verify GitHub classic branch protection: main, develop"
    return 0
  fi

  if ! project_github_context_ready "GitHub repository settings sync"; then
    return 0
  fi

  repo_slug=$(github_repo_slug)
  sync_repository_general_settings "$repo_slug"
  ensure_github_branch "$repo_slug" "develop" "main"
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
      --github-account|--git-account)
        github_account_option="$1"
        shift
        [ "$#" -gt 0 ] || error "$github_account_option requires a value"
        GITHUB_ACCOUNT="$1"
        ;;
      --github-host)
        shift
        [ "$#" -gt 0 ] || error "--github-host requires a value"
        GITHUB_HOST="$1"
        ;;
      --configure-git-user)
        CONFIGURE_GIT_USER=1
        ;;
      --git-user-name)
        shift
        [ "$#" -gt 0 ] || error "--git-user-name requires a value"
        GIT_USER_NAME="$1"
        CONFIGURE_GIT_USER=1
        ;;
      --git-user-email)
        shift
        [ "$#" -gt 0 ] || error "--git-user-email requires a value"
        GIT_USER_EMAIL="$1"
        CONFIGURE_GIT_USER=1
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

  if [ "$SCOPE" = "project" ] && [ -z "$GITHUB_ACCOUNT" ]; then
    error "project scope requires --github-account <account> or SPAI_GITHUB_ACCOUNT."
  fi

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
  sync_local_git_user_config
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
  [ "$DRY_RUN" -eq 1 ] || print_list "Deleted GitHub labels" "$DELETED_LABELS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub labels" "$VERIFIED_LABELS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub account" "$VERIFIED_GITHUB_ACCOUNT"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced local git config" "$SYNCED_GIT_CONFIG"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub repository settings" "$SYNCED_REPOSITORY_SETTINGS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub branches" "$SYNCED_BRANCHES"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub branches" "$VERIFIED_BRANCHES"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub branch protections" "$SYNCED_BRANCH_PROTECTIONS"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub branch protections" "$VERIFIED_BRANCH_PROTECTIONS"
}

main "$@"
