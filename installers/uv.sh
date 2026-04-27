#!/usr/bin/env bash
set -euo pipefail

# uv (https://docs.astral.sh/uv/) — Astral Python package & project manager.

install_uv() {
  if command_exists uv; then
    log_info "uv already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install uv (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install uv
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for uv on macOS"
      return 1
    fi
    brew install uv
  elif is_debian_like; then
    log_info "installing uv via upstream installer"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    log_error "no uv install path for $DISTRO"
    return 1
  fi
}

install_uv
