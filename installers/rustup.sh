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

  # Source cargo env to make it available immediately
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi

  log_info "Rust installed and cargo available in PATH"
}

install_rustup
