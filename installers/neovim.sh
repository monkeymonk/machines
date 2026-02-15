#!/usr/bin/env bash
set -euo pipefail

# Install neovim using bob-nvim (neovim version manager)
install_neovim() {
  local dry_run="${DRY_RUN:-false}"

  # Ensure bob is available
  if ! command -v bob >/dev/null 2>&1; then
    log_warn "bob-nvim not found, skipping neovim installation"
    return 0
  fi

  # Check if nvim is already installed via bob
  if command -v nvim >/dev/null 2>&1; then
    log_info "neovim already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install neovim stable via bob (dry-run)"
    return 0
  fi

  log_info "Installing neovim stable via bob"
  bob install stable
  bob use stable

  log_info "neovim installed successfully"
}

install_neovim
