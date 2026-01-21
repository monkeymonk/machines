#!/usr/bin/env bash
set -euo pipefail

# macOS-specific tweaks that run before package installs.
bootstrap_macos() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Running macOS bootstrap hooks"

  if command -v brew >/dev/null 2>&1; then
    log_info "Homebrew already installed"
  else
    if [[ "$dry_run" == true ]]; then
      log_info "Would install Homebrew (dry-run)"
    else
      log_info "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would update Homebrew (dry-run)"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    brew update
  else
    log_warn "Homebrew not available; skipping brew update"
  fi
}
