#!/usr/bin/env sh
set -eu

TARGET=""
SCOPE="project"
DRY_RUN=0
FORCE=0
GITHUB_ACCOUNT="${SPAI_GITHUB_PROFILE:-${SPAI_GITHUB_ACCOUNT:-}}"
GITHUB_HOST="${SPAI_GITHUB_HOST:-}"
GITHUB_AUTH_TOKEN=""
GITHUB_PROFILE_SOURCE=""
if [ -n "${SPAI_GITHUB_PROFILE:-}" ]; then
  GITHUB_PROFILE_SOURCE="SPAI_GITHUB_PROFILE"
elif [ -n "${SPAI_GITHUB_ACCOUNT:-}" ]; then
  GITHUB_PROFILE_SOURCE="SPAI_GITHUB_ACCOUNT"
fi
CONFIGURE_GIT_USER="${SPAI_CONFIGURE_GIT_USER:-0}"
GIT_USER_NAME="${SPAI_GIT_USER_NAME:-}"
GIT_USER_EMAIL="${SPAI_GIT_USER_EMAIL:-}"
REPO_RAW_URL_INPUT="${REPO_RAW_URL:-}"
REPO_RAW_URL=""
REPO_RAW_BASE="${SPAI_REPO_RAW_BASE:-https://raw.githubusercontent.com/0x0w1/spai}"
SPAI_RELEASES_API="${SPAI_RELEASES_API:-https://api.github.com/repos/0x0w1/spai/releases/latest}"
REQUESTED_VERSION="${SPAI_VERSION:-}"
SPAI_VERSION_STAMP="main"
SKILLS_INPUT="${SPAI_SKILLS:-}"
SELECTED_SKILLS=""
MANIFEST_TMP=""
INSTALLED_FILES=""
VERIFIED_GITHUB_ACCOUNT=""
SYNCED_GIT_CONFIG=""
SYNCED_BRANCHES=""
VERIFIED_BRANCHES=""

print_help() {
  cat <<'EOF'
SPAI - Scaffolded Procedures for AI Agents

This installer covers the CLIs that have no plugin system. Claude Code is not a target:
it installs the spai plugin from the Claude Code marketplace instead.

  /plugin marketplace add 0x0w1/spai
  /plugin install spai@spai

Usage:
  sh install.sh --target <target> [--scope <scope>] [--github-profile <profile>] [--version vX.Y.Z] [--skills a,b,c] [--configure-git-user] [--dry-run] [--force]

Merge flow:
  Work branches squash-merge into develop locally and develop is pushed directly. No pull requests.

Skills:
  Default: every skill marked default in dist/manifest.tsv.
  Use --skills a,b,c (or SPAI_SKILLS) to install a subset; names must exist in the manifest.

Targets:
  codex
  antigravity

  --target is required and takes exactly one target. Install one CLI per run.

Scopes:
  project
  global

Defaults:
  --scope project

Examples:
  wget -qO- https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target codex --scope project --github-profile your-account

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target antigravity --scope project --github-profile your-account

Environment:
  SPAI_GITHUB_PROFILE=your-account sh install.sh --target codex --scope project
  REPO_RAW_URL=https://raw.githubusercontent.com/my-org/spai/main SPAI_GITHUB_PROFILE=your-account sh install.sh --target codex
  SPAI_VERSION=v0.1.0 SPAI_GITHUB_PROFILE=your-account sh install.sh --target codex --scope project
  SPAI_SKILLS=github-release,develop-task-flow SPAI_GITHUB_PROFILE=your-account sh install.sh --target codex --scope project
  SPAI_GITHUB_HOST=github.example.com SPAI_GITHUB_PROFILE=your-account sh install.sh --target codex --scope project
  SPAI_GIT_USER_NAME="Your Name" SPAI_GIT_USER_EMAIL=your@email.com sh install.sh --target codex --scope project --github-profile your-account

Version:
  By default the installer resolves the latest GitHub release tag and installs the payload
  pinned to that tag (raw.githubusercontent.com/0x0w1/spai/vX.Y.Z). If the release lookup
  fails, it falls back to the main branch.
  Use --version vX.Y.Z (or SPAI_VERSION) to pin or roll back to a specific release.
  An explicit REPO_RAW_URL overrides version resolution entirely.
  The installed version and skill selection are stamped as
  <!-- spai:version vX.Y.Z skills=<a,b,c> --> inside the SPAI managed block of
  AGENTS.md / GEMINI.md; the spai-update and spai-doctor skills read this stamp.

GitHub profile:
  Project scope resolves --github-profile, SPAI_GITHUB_PROFILE, then local git config spai.githubProfile.
  --github-account and SPAI_GITHUB_ACCOUNT remain supported aliases.
  Use --github-host <host> or SPAI_GITHUB_HOST for GitHub Enterprise hosts.
  The installer logs in with gh when needed and uses that profile per command without changing the globally active account.

Local git user:
  Use --configure-git-user to prompt for local user.name and user.email.
  Use --git-user-name and --git-user-email, or SPAI_GIT_USER_NAME and SPAI_GIT_USER_EMAIL, to set them non-interactively.

Managed files:
  Use --force to replace an existing managed file entirely when it does not already contain SPAI markers.

Skill ownership:
  codex and antigravity have no plugin system, so their skill directories carry a spai- prefix
  (.agents/skills/spai-github-sync, ...) to stay clear of your own skill names.

Project scope also syncs GitHub repository settings when gh is available:
  profile: selected by --github-profile, SPAI_GITHUB_PROFILE, or local git config
  branches: develop creation from main when missing

Target-specific project installs:
  codex: AGENTS.md plus .agents/skills/spai-*
  antigravity: GEMINI.md plus .agents/skills/spai-*
EOF
}

log() {
  printf 'SPAI [info] %s\n' "$*"
}

pass_task() {
  log "PASS: $*"
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
    error "interactive input requires a terminal. Pass the required option values non-interactively instead."
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

is_valid_release_version() {
  printf '%s' "$1" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'
}

fetch_latest_release_tag() {
  if command -v gh >/dev/null 2>&1; then
    gh_latest_tag=$(gh api "$SPAI_RELEASES_API" --jq .tag_name 2>/dev/null || true)
    if [ -n "$gh_latest_tag" ]; then
      printf '%s\n' "$gh_latest_tag"
      return 0
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SPAI_RELEASES_API" 2>/dev/null
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$SPAI_RELEASES_API" 2>/dev/null
  fi | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

resolve_repo_raw_url() {
  if [ -n "$REPO_RAW_URL_INPUT" ]; then
    REPO_RAW_URL="$REPO_RAW_URL_INPUT"
    SPAI_VERSION_STAMP="${REQUESTED_VERSION:-custom}"
    log "SPAI payload source (REPO_RAW_URL override): $REPO_RAW_URL"
    return 0
  fi

  if [ -n "$REQUESTED_VERSION" ]; then
    if ! is_valid_release_version "$REQUESTED_VERSION"; then
      error "--version must match vX.Y.Z: $REQUESTED_VERSION"
    fi
    REPO_RAW_URL="$REPO_RAW_BASE/$REQUESTED_VERSION"
    SPAI_VERSION_STAMP="$REQUESTED_VERSION"
    log "SPAI payload source (pinned): $REPO_RAW_URL"
    return 0
  fi

  latest_release_tag=$(fetch_latest_release_tag || true)
  if is_valid_release_version "${latest_release_tag:-}"; then
    REPO_RAW_URL="$REPO_RAW_BASE/$latest_release_tag"
    SPAI_VERSION_STAMP="$latest_release_tag"
    log "SPAI payload source (latest release): $REPO_RAW_URL"
    return 0
  fi

  REPO_RAW_URL="$REPO_RAW_BASE/main"
  SPAI_VERSION_STAMP="main"
  warn "Latest release lookup failed; falling back to main branch payload."
  log "SPAI payload source (fallback): $REPO_RAW_URL"
}

stamp_spai_version() {
  stamp_target="$1"
  stamp_tmp=$(mktemp)
  stamp_skills=$(printf '%s' "$SELECTED_SKILLS" | tr ' ' ',' | sed 's/^,*//; s/,*$//; s/,,*/,/g')
  sed "s|<!-- spai:version dev -->|<!-- spai:version $SPAI_VERSION_STAMP skills=$stamp_skills -->|" "$stamp_target" > "$stamp_tmp"
  mv "$stamp_tmp" "$stamp_target"
}

load_manifest() {
  MANIFEST_TMP=$(mktemp)
  download_file "$REPO_RAW_URL/dist/manifest.tsv" "$MANIFEST_TMP"
}

manifest_default_skills() {
  awk -F '\t' '
    !/^#/ && NF >= 3 && $3 == "yes" { printf "%s ", $1 }
  ' "$MANIFEST_TMP"
}

skill_selected() {
  for selected_skill in $SELECTED_SKILLS; do
    [ "$selected_skill" = "$1" ] && return 0
  done
  return 1
}

prefixed_skill_name() {
  case "$1" in
    spai-*) printf '%s' "$1" ;;
    *) printf 'spai-%s' "$1" ;;
  esac
}

manifest_all_skills() {
  awk -F '\t' '
    !/^#/ && NF >= 3 { printf "%s ", $1 }
  ' "$MANIFEST_TMP"
}

manifest_has_skill() {
  awk -F '\t' -v name="$1" '
    !/^#/ && $1 == name { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$MANIFEST_TMP"
}

resolve_selected_skills() {
  if [ -z "$SKILLS_INPUT" ]; then
    SELECTED_SKILLS=$(manifest_default_skills)
  else
    SELECTED_SKILLS=""
    for requested_skill in $(printf '%s' "$SKILLS_INPUT" | tr ',' ' '); do
      manifest_has_skill "$requested_skill" || error "unknown skill: $requested_skill"
      SELECTED_SKILLS="$SELECTED_SKILLS $requested_skill"
    done
  fi
  [ -n "${SELECTED_SKILLS# }" ] || error "no skills selected."
  log "Selected skills:$(printf ' %s' $SELECTED_SKILLS)"
}

record_installed() {
  INSTALLED_FILES="${INSTALLED_FILES}
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

record_branch() {
  SYNCED_BRANCHES="${SYNCED_BRANCHES}
$1"
}

record_verified_branch() {
  VERIFIED_BRANCHES="${VERIFIED_BRANCHES}
$1"
}

resolve_github_profile_config() {
  if [ "$SCOPE" = "project" ] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ -z "$GITHUB_ACCOUNT" ]; then
      GITHUB_ACCOUNT=$(git config --local --get spai.githubProfile 2>/dev/null || true)
      [ -z "$GITHUB_ACCOUNT" ] || GITHUB_PROFILE_SOURCE="local git config"
    fi
    if [ -z "$GITHUB_HOST" ]; then
      GITHUB_HOST=$(git config --local --get spai.githubHost 2>/dev/null || true)
    fi
  fi

  [ -n "$GITHUB_HOST" ] || GITHUB_HOST="github.com"
}

copy_file_with_backup() {
  copy_source_url="$1"
  copy_destination="$2"

  copy_tmp=$(mktemp)
  download_file "$copy_source_url" "$copy_tmp"

  if [ ! -f "$copy_destination" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "[dry-run] Would install missing file: $copy_destination"
      rm -f "$copy_tmp"
      return 0
    fi

    mkdir -p "$(dirname "$copy_destination")"
    cp "$copy_tmp" "$copy_destination"
    record_installed "$copy_destination"
    rm -f "$copy_tmp"
    return 0
  fi

  if cmp -s "$copy_tmp" "$copy_destination"; then
    pass_task "unchanged file: $copy_destination"
    rm -f "$copy_tmp"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would update changed file: $copy_destination"
    rm -f "$copy_tmp"
    return 0
  fi

  mkdir -p "$(dirname "$copy_destination")"
  cp "$copy_destination" "$copy_destination.bak"
  cp "$copy_tmp" "$copy_destination"
  record_installed "$copy_destination"
  rm -f "$copy_tmp"
}

filter_managed_block_skills() {
  filter_target="$1"

  for candidate_skill in $(manifest_all_skills); do
    skill_selected "$candidate_skill" && continue
    filter_tmp=$(mktemp)
    awk -v prefixed="$(prefixed_skill_name "$candidate_skill")" '
      $0 ~ ("^- `" prefixed "`") { next }
      { print }
    ' "$filter_target" > "$filter_tmp"
    mv "$filter_tmp" "$filter_target"
  done
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

  managed_source_tmp=$(mktemp)
  managed_block_tmp=$(mktemp)
  managed_new_tmp=$(mktemp)
  download_file "$managed_source_url" "$managed_source_tmp"
  stamp_spai_version "$managed_source_tmp"
  filter_managed_block_skills "$managed_source_tmp"
  extract_managed_block "$managed_source_tmp" "$managed_block_tmp" "$managed_start_marker" "$managed_end_marker"

  if [ ! -f "$managed_destination" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "[dry-run] Would install missing managed file: $managed_destination"
      rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
      return 0
    fi

    mkdir -p "$(dirname "$managed_destination")"
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
    managed_action="append"
    if [ "$FORCE" -eq 1 ]; then
      managed_action="replace"
      if [ "$DRY_RUN" -eq 1 ]; then
        log "[dry-run] Would replace existing managed file: $managed_destination"
        rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
        return 0
      fi

      mkdir -p "$(dirname "$managed_destination")"
      cp "$managed_destination" "$managed_destination.bak"
      cp "$managed_source_tmp" "$managed_destination"
      record_installed "$managed_destination"
      rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
      return 0
    fi

    cp "$managed_destination" "$managed_new_tmp"
    if [ -s "$managed_new_tmp" ]; then
      printf '\n' >> "$managed_new_tmp"
    fi
    cat "$managed_block_tmp" >> "$managed_new_tmp"
  fi

  if cmp -s "$managed_new_tmp" "$managed_destination"; then
    pass_task "unchanged managed block: $managed_destination"
    rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ "${managed_action:-update}" = "append" ]; then
      log "[dry-run] Would append managed block to existing file: $managed_destination"
    else
      log "[dry-run] Would update changed managed block: $managed_destination"
    fi
    rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
    return 0
  fi

  mkdir -p "$(dirname "$managed_destination")"
  cp "$managed_destination" "$managed_destination.bak"
  cp "$managed_new_tmp" "$managed_destination"
  record_installed "$managed_destination"
  rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
}

sync_local_git_user_config() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$CONFIGURE_GIT_USER" != "1" ] && [ -z "$GIT_USER_NAME" ] && [ -z "$GIT_USER_EMAIL" ]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "[dry-run] Would require git to configure local user.name/user.email"
      return 0
    fi
    error "git is required to configure local user.name/user.email."
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "[dry-run] Would require a git repository to configure local user.name/user.email"
      return 0
    fi
    error "local git user config requires running inside a git repository."
  fi

  current_git_user_name=$(git config --local --get user.name 2>/dev/null || true)
  current_git_user_email=$(git config --local --get user.email 2>/dev/null || true)
  log "Current local git user.name: ${current_git_user_name:-unset}"
  log "Current local git user.email: ${current_git_user_email:-unset}"

  target_git_user_name="$GIT_USER_NAME"
  target_git_user_email="$GIT_USER_EMAIL"
  prompt_git_user_name=0
  prompt_git_user_email=0

  if [ -z "$target_git_user_name" ]; then
    if [ -n "$current_git_user_name" ]; then
      target_git_user_name="$current_git_user_name"
    else
      prompt_git_user_name=1
    fi
  fi

  if [ -z "$target_git_user_email" ]; then
    if [ -n "$current_git_user_email" ]; then
      target_git_user_email="$current_git_user_email"
    else
      prompt_git_user_email=1
    fi
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ "$prompt_git_user_name" -eq 1 ]; then
      log "[dry-run] Would prompt for missing local git user.name"
    elif [ "$current_git_user_name" != "$target_git_user_name" ]; then
      log "[dry-run] Would set local git user.name: $target_git_user_name"
    fi

    if [ "$prompt_git_user_email" -eq 1 ]; then
      log "[dry-run] Would prompt for missing local git user.email"
    elif [ "$current_git_user_email" != "$target_git_user_email" ]; then
      log "[dry-run] Would set local git user.email: $target_git_user_email"
    fi

    if [ "$prompt_git_user_name" -eq 0 ] &&
      [ "$prompt_git_user_email" -eq 0 ] &&
      [ "$current_git_user_name" = "$target_git_user_name" ] &&
      [ "$current_git_user_email" = "$target_git_user_email" ]; then
      pass_task "local git user config already complete"
    fi
    return 0
  fi

  if [ "$prompt_git_user_name" -eq 1 ]; then
    target_git_user_name=$(prompt_tty "Local git user.name: ")
  fi

  if [ "$prompt_git_user_email" -eq 1 ]; then
    target_git_user_email=$(prompt_tty "Local git user.email: ")
  fi

  [ -n "$target_git_user_name" ] || error "local git user.name is required."
  [ -n "$target_git_user_email" ] || error "local git user.email is required."

  git_config_changed=0

  if [ "$current_git_user_name" = "$target_git_user_name" ]; then
    pass_task "local git user.name already set: $target_git_user_name"
  else
    git config --local user.name "$target_git_user_name"
    record_git_config "user.name=$target_git_user_name"
    git_config_changed=1
  fi

  if [ "$current_git_user_email" = "$target_git_user_email" ]; then
    pass_task "local git user.email already set: $target_git_user_email"
  else
    git config --local user.email "$target_git_user_email"
    record_git_config "user.email=$target_git_user_email"
    git_config_changed=1
  fi

  if [ "$git_config_changed" -eq 1 ]; then
    log "Local git user config updated"
  else
    pass_task "local git user config already complete"
  fi
}

gh_with_profile() {
  case "$GITHUB_HOST" in
    github.com|*.ghe.com)
      GH_TOKEN="$GITHUB_AUTH_TOKEN" GH_HOST="$GITHUB_HOST" gh "$@"
      ;;
    *)
      GH_ENTERPRISE_TOKEN="$GITHUB_AUTH_TOKEN" GH_HOST="$GITHUB_HOST" gh "$@"
      ;;
  esac
}

ensure_github_login() {
  if GITHUB_AUTH_TOKEN=$(gh auth token --hostname "$GITHUB_HOST" --user "$GITHUB_ACCOUNT" 2>/dev/null); then
    return 0
  fi

  warn "GitHub CLI account is not available yet: $GITHUB_ACCOUNT@$GITHUB_HOST"
  log "Starting GitHub CLI login for $GITHUB_HOST"
  if ! gh auth login --hostname "$GITHUB_HOST"; then
    error "GitHub CLI login failed for $GITHUB_HOST."
  fi

  if ! GITHUB_AUTH_TOKEN=$(gh auth token --hostname "$GITHUB_HOST" --user "$GITHUB_ACCOUNT" 2>/dev/null); then
    error "GitHub profile is unavailable after login: $GITHUB_ACCOUNT@$GITHUB_HOST"
  fi
}

select_github_account() {
  context_action="$1"

  if [ -n "$VERIFIED_GITHUB_ACCOUNT" ]; then
    return 0
  fi

  if [ -z "$GITHUB_ACCOUNT" ]; then
    error "GitHub profile is required for $context_action. Pass --github-profile <profile>, set SPAI_GITHUB_PROFILE, or configure spai.githubProfile locally."
  fi

  ensure_github_login

  verified_account=$(gh_with_profile api user --jq .login 2>/dev/null || true)
  if [ "$verified_account" != "$GITHUB_ACCOUNT" ]; then
    error "GitHub profile verification failed: expected $GITHUB_ACCOUNT on $GITHUB_HOST, got ${verified_account:-unknown}."
  fi

  log "GitHub CLI profile selected without changing the global active account: $GITHUB_ACCOUNT@$GITHUB_HOST"
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

  if ! gh_with_profile repo view >/dev/null 2>&1; then
    warn "GitHub repository check failed: current directory is not connected to a GitHub repository. Skipping $context_action."
    return 1
  fi
  log "GitHub repository check passed"

  return 0
}

github_repo_slug() {
  gh_with_profile repo view --json nameWithOwner --jq .nameWithOwner
}

github_repo_visibility() {
  repo_visibility=$(gh_with_profile repo view --json visibility --jq .visibility 2>/dev/null || true)
  if [ -n "$repo_visibility" ]; then
    printf '%s\n' "$repo_visibility"
  else
    printf 'unknown\n'
  fi
}

github_repo_viewer_permission() {
  repo_viewer_permission=$(gh_with_profile repo view --json viewerPermission --jq .viewerPermission 2>/dev/null || true)
  if [ -n "$repo_viewer_permission" ]; then
    printf '%s\n' "$repo_viewer_permission"
  else
    printf 'unknown\n'
  fi
}

github_branch_exists() {
  repo_slug="$1"
  branch_name="$2"
  gh_with_profile api "repos/$repo_slug/branches/$branch_name" >/dev/null 2>&1
}

github_branch_sha() {
  repo_slug="$1"
  branch_name="$2"
  gh_with_profile api "repos/$repo_slug/branches/$branch_name" --jq .commit.sha 2>/dev/null || true
}

ensure_github_branch() {
  repo_slug="$1"
  branch_name="$2"
  source_branch="$3"

  if github_branch_exists "$repo_slug" "$branch_name"; then
    pass_task "GitHub branch exists: $branch_name"
    record_verified_branch "$branch_name (exists)"
    return 0
  fi

  source_sha=$(github_branch_sha "$repo_slug" "$source_branch")
  if [ -z "$source_sha" ]; then
    warn "GitHub branch creation skipped: source branch $source_branch does not exist."
    return 0
  fi

  if gh_with_profile api -X POST "repos/$repo_slug/git/refs" -f ref="refs/heads/$branch_name" -f sha="$source_sha" >/dev/null 2>&1; then
    log "GitHub branch created: $branch_name from $source_branch"
    record_branch "$branch_name (created from $source_branch)"
  elif github_branch_exists "$repo_slug" "$branch_name"; then
    pass_task "GitHub branch exists: $branch_name"
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

sync_github_repository_settings() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would use GitHub CLI account: $GITHUB_ACCOUNT@$GITHUB_HOST"
    log "[dry-run] Would inspect GitHub repository visibility and viewer permission"
    log "[dry-run] Would ensure GitHub branch exists: develop (created from main if missing)"
    return 0
  fi

  if ! project_github_context_ready "GitHub repository settings sync"; then
    return 0
  fi

  repo_slug=$(github_repo_slug)
  repo_visibility=$(github_repo_visibility)
  repo_viewer_permission=$(github_repo_viewer_permission)
  log "GitHub repository context: $repo_slug (visibility=$repo_visibility, permission=$repo_viewer_permission)"

  ensure_github_branch "$repo_slug" "develop" "main"
}

print_guide() {
  if [ "$SCOPE" != "project" ]; then
    return 0
  fi

  printf '\nGUIDE\n'
  printf '%s\n' '  Remaining manual steps:'
  printf '%s\n' '    - Protect `main` and `develop` against force pushes and deletion; do not require pull requests.'
  printf '%s\n' '    - Use the installed `spai-github-sync` skill to apply or verify this branch protection.'
}

install_codex() {
  if [ "$SCOPE" = "project" ]; then
    destination="./AGENTS.md"
    skill_base="./.agents/skills"
  else
    destination="$HOME/.codex/AGENTS.md"
    skill_base="$HOME/.agents/skills"
  fi
  for skill in $SELECTED_SKILLS; do
    prefixed=$(prefixed_skill_name "$skill")
    copy_file_with_backup "$REPO_RAW_URL/dist/codex/.agents/skills/$prefixed/SKILL.md" "$skill_base/$prefixed/SKILL.md"
  done
  install_managed_block "$REPO_RAW_URL/dist/codex/AGENTS.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_antigravity() {
  if [ "$SCOPE" = "project" ]; then
    destination="./GEMINI.md"
    skill_base="./.agents/skills"
  else
    destination="$HOME/.gemini/GEMINI.md"
    skill_base="$HOME/.gemini/config/skills"
  fi
  for skill in $SELECTED_SKILLS; do
    prefixed=$(prefixed_skill_name "$skill")
    copy_file_with_backup "$REPO_RAW_URL/dist/antigravity/.agents/skills/$prefixed/SKILL.md" "$skill_base/$prefixed/SKILL.md"
  done
  install_managed_block "$REPO_RAW_URL/dist/antigravity/GEMINI.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_target() {
  case "$1" in
    codex) install_codex ;;
    antigravity) install_antigravity ;;
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
      --github-profile|--github-account|--git-account)
        github_account_option="$1"
        shift
        [ "$#" -gt 0 ] || error "$github_account_option requires a value"
        GITHUB_ACCOUNT="$1"
        GITHUB_PROFILE_SOURCE="$github_account_option"
        ;;
      --github-host)
        shift
        [ "$#" -gt 0 ] || error "--github-host requires a value"
        GITHUB_HOST="$1"
        ;;
      --version)
        shift
        [ "$#" -gt 0 ] || error "--version requires a value"
        REQUESTED_VERSION="$1"
        ;;
      --skills)
        shift
        [ "$#" -gt 0 ] || error "--skills requires a value"
        SKILLS_INPUT="$1"
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
    codex|antigravity) ;;
    "") error "--target is required. Supported targets: codex, antigravity. Claude Code installs the spai plugin instead: /plugin marketplace add 0x0w1/spai then /plugin install spai@spai." ;;
    claude-code|all) error "unsupported target: $TARGET. Install one of codex or antigravity per run. Claude Code installs the spai plugin instead: /plugin marketplace add 0x0w1/spai then /plugin install spai@spai." ;;
    *) error "unsupported target: $TARGET" ;;
  esac

  case "$SCOPE" in
    project|global) ;;
    *) error "unsupported scope: $SCOPE" ;;
  esac

  resolve_github_profile_config

  if [ "$SCOPE" = "project" ] && [ -z "$GITHUB_ACCOUNT" ]; then
    error "project scope requires --github-profile <profile>, SPAI_GITHUB_PROFILE, or local git config spai.githubProfile."
  fi
  if [ "$SCOPE" = "project" ]; then
    log "GitHub profile source: ${GITHUB_PROFILE_SOURCE:-explicit input}"
  fi

  need_downloader
  resolve_repo_raw_url
  load_manifest
  resolve_selected_skills

  install_target "$TARGET"

  sync_local_git_user_config
  sync_github_repository_settings

  log "Installation complete"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run only; no files were modified."
  elif [ -n "$INSTALLED_FILES" ]; then
    print_list "Installed files" "$INSTALLED_FILES"
  else
    log "No file changes"
  fi

  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub account" "$VERIFIED_GITHUB_ACCOUNT"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced local git config" "$SYNCED_GIT_CONFIG"
  [ "$DRY_RUN" -eq 1 ] || print_list "Synced GitHub branches" "$SYNCED_BRANCHES"
  [ "$DRY_RUN" -eq 1 ] || print_list "Verified GitHub branches" "$VERIFIED_BRANCHES"
  print_guide
}

main "$@"
