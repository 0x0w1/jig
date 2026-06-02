#!/usr/bin/env sh
set -eu

TARGET="all"
SCOPE="project"
DRY_RUN=0
FORCE=0
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/0x0w1/spai/main}"
INSTALLED_FILES=""

print_help() {
  cat <<'EOF'
SPAI - Scaffolded Procedures for AI Agents

Usage:
  sh install.sh [--target <target>] [--scope <scope>] [--dry-run] [--force]

Targets:
  claude-code
  codex
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
  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target claude-code --scope project

  wget -qO- https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target codex --scope project

  curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/main/install.sh \
    | sh -s -- --target all --scope project

Environment:
  REPO_RAW_URL=https://raw.githubusercontent.com/my-org/spai/main sh install.sh
EOF
}

log() {
  echo "spai: $*"
}

warn() {
  echo "spai: warning: $*" >&2
}

error() {
  echo "spai: error: $*" >&2
  exit 1
}

need_downloader() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    return 0
  fi
  error "curl 또는 wget이 필요합니다."
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
    error "download failed: curl 또는 wget이 없습니다."
  fi
}

record_installed() {
  INSTALLED_FILES="${INSTALLED_FILES}
$1"
}

copy_file_with_backup() {
  copy_source_url="$1"
  copy_destination="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] copy $copy_source_url -> $copy_destination"
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
    log "skip unchanged: $copy_destination"
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
    log "[dry-run] managed block $managed_source_url -> $managed_destination"
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
    log "skip unchanged: $managed_destination"
    rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
    return 0
  fi

  cp "$managed_destination" "$managed_destination.bak"
  cp "$managed_new_tmp" "$managed_destination"
  record_installed "$managed_destination"
  rm -f "$managed_source_tmp" "$managed_block_tmp" "$managed_new_tmp"
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
    error "Cursor target은 현재 project scope 설치만 지원합니다. --scope project를 사용하세요."
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
    install_target claude-code
    install_target codex
    if [ "$SCOPE" = "global" ]; then
      warn "Cursor target은 현재 project scope 설치만 지원하므로 건너뜁니다."
    else
      install_target cursor
    fi
    install_target gemini-cli
    install_target opencode
  else
    install_target "$TARGET"
  fi

  log "installation complete"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run only; no files were modified"
  elif [ -n "$INSTALLED_FILES" ]; then
    printf '%s\n' "Installed files:$INSTALLED_FILES"
  else
    log "no file changes"
  fi
}

main "$@"
