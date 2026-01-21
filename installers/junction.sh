#!/usr/bin/env bash
set -euo pipefail

install_junction() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists junction; then
    log_info "Junction already installed"
    return 0
  fi

  log_info "Installing Junction"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Junction (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install Junction"
      return 1
    fi
    brew install junction
  else
    pkg_install junction
  fi
}

install_junction
