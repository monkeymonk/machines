#!/usr/bin/env bash
set -euo pipefail

install_ripgrep() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists rg; then
    log_info "ripgrep already installed"
    return 0
  fi

  log_info "Installing ripgrep"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install ripgrep (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install ripgrep"
      return 1
    fi
    brew install ripgrep
  else
    pkg_install ripgrep
  fi
}

install_ripgrep
