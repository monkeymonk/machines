#!/usr/bin/env bash
set -euo pipefail

install_wezterm() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists wezterm; then
    log_info "WezTerm already installed"
    return 0
  fi

  log_info "Installing WezTerm"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install WezTerm (dry-run)"
    return 0
  fi

  if is_macos; then
    if command_exists brew; then
      brew install wezterm
    else
      log_warn "Homebrew not available; falling back to package manager"
      install_package wezterm
    fi
    return 0
  fi

  install_package cargo

  if ! command_exists cargo; then
    log_error "Cargo not found; cannot build WezTerm"
    return 1
  fi
  log_info "Compiling WezTerm via cargo"
  cargo install --locked wezterm
  local cargo_home="${CARGO_HOME:-$HOME/.cargo}"
  log_info "WezTerm installed; add $cargo_home/bin to PATH if needed"
}

install_wezterm
