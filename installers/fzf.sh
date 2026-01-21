#!/usr/bin/env bash
set -euo pipefail

install_fzf() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists fzf; then
    log_info "fzf already installed"
    return 0
  fi

  log_info "Installing fzf"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install fzf (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install fzf"
      return 1
    fi
    brew install fzf
  else
    pkg_install fzf
  fi
}

install_fzf
