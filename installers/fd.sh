#!/usr/bin/env bash
set -euo pipefail

install_fd() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists fd; then
    log_info "fd already installed"
    return 0
  fi

  log_info "Installing fd"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install fd (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install fd"
      return 1
    fi
    brew install fd
    return 0
  fi

  if is_debian_like; then
    pkg_install fd-find
    if command_exists fdfind; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      log_info "Symlinked fdfind to $HOME/.local/bin/fd"
    else
      log_warn "fd-find installed but fdfind not found"
    fi
    return 0
  fi

  pkg_install fd
}

install_fd
