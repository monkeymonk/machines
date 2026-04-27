#!/usr/bin/env bash
set -euo pipefail

# mise (https://mise.jdx.dev) — language version manager replacing nvm/pyenv/etc.

install_mise() {
  if command_exists mise; then
    log_info "mise already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install mise (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install mise
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for mise on macOS"
      return 1
    fi
    brew install mise
  elif is_debian_like; then
    log_info "installing mise via upstream installer"
    curl -fsSL https://mise.run | sh
  else
    log_error "no mise install path for $DISTRO"
    return 1
  fi
}

install_mise
