#!/usr/bin/env bash
set -euo pipefail

install_rustup() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists rustup; then
    log_info "rustup already installed"
    return 0
  fi

  log_info "Installing rustup"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install rustup via installer script (dry-run)"
    return 0
  fi

  curl -fsSL https://sh.rustup.rs | sh -s -- -y
  log_info "Rust installed; add $HOME/.cargo/bin to PATH if needed"
}

install_rustup
