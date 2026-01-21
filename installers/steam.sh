#!/usr/bin/env bash
set -euo pipefail

install_steam() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists steam; then
    log_info "Steam already installed"
    return 0
  fi

  log_info "Installing Steam"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Steam (dry-run)"
    return 0
  fi

  if is_macos; then
    if command_exists brew; then
      brew install --cask steam
    else
      log_warn "Homebrew not available; cannot install Steam"
    fi
  else
    pkg_install steam
  fi
}

install_steam
