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

  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI check failed: gh is not installed. Skipping GitHub label sync."
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI check failed: gh authentication is not available. Skipping GitHub label sync."
    return 0
  fi
  log "GitHub CLI check passed"

  if ! command -v git >/dev/null 2>&1; then
    log "Git repository check passed: git is not installed, so GitHub label sync was skipped."
    return 0
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Git repository check passed: no .git repository found, so GitHub label sync was skipped."
    return 0
  fi
  log "Git repository check passed"

  if ! gh repo view >/dev/null 2>&1; then
    warn "GitHub repository check failed: current directory is not connected to a GitHub repository. Skipping GitHub label sync."
    return 0
  fi
  log "GitHub repository check passed"

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

install_claude_code() {
  if [ "$SCOPE" = "project" ]; then
    base="./.claude/skills/github-release-setup"
  else
    base="$HOME/.claude/skills/github-release-setup"
  fi
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/skills/github-release-setup/SKILL.md" "$base/SKILL.md"
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/skills/github-release-setup/files/drafter-config.yaml" "$base/files/drafter-config.yaml"
  copy_file_with_backup "$REPO_RAW_URL/dist/claude-code/skills/github-release-setup/files/drafter.yaml" "$base/files/drafter.yaml"
}

install_codex() {
  if [ "$SCOPE" = "project" ]; then
    destination="./AGENTS.md"
  else
    destination="$HOME/.codex/AGENTS.md"
  fi
  install_managed_block "$REPO_RAW_URL/dist/codex/AGENTS.md" "$destination" "<!-- spai:start github-release-setup -->" "<!-- spai:end github-release-setup -->"
}

install_cursor() {
  if [ "$SCOPE" = "global" ]; then
    error "The cursor target currently supports project scope only. Use --scope project."
  fi
  copy_file_with_backup "$REPO_RAW_URL/dist/cursor/.cursor/rules/github-release-setup.mdc" "./.cursor/rules/github-release-setup.mdc"
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
}

main "$@"
