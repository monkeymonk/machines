#!/usr/bin/env bash
set -euo pipefail

install_pyenv() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Ensuring Python is installed"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Python dependencies (dry-run)"
  else
    if is_macos; then
      if ! command_exists brew; then
        log_error "Homebrew not available; cannot install Python"
        return 1
      fi
      brew install python
    elif is_arch; then
      pkg_install python
      pkg_install python-pip
    elif is_debian_like; then
      pkg_install python3
      pkg_install python3-venv
      # Force install python3-pip
      sudo apt-get install -y python3-pip
      # Verify pip works
      if ! python3 -m pip --version &>/dev/null; then
        log_warn "pip installation may have failed, attempting ensurepip"
        python3 -m ensurepip --default-pip 2>/dev/null || true
      fi
    else
      pkg_install python3
    fi
  fi

  if command_exists pyenv; then
    log_info "pyenv already installed"
    return 0
  fi

  log_info "Installing pyenv"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install pyenv (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install pyenv"
      return 1
    fi
    brew install pyenv
  else
    # Verify pip is available before running pyenv installer
    if ! python3 -m pip --version &>/dev/null; then
      log_error "pip not available, cannot install pyenv"
      return 1
    fi
    curl -fsSL https://pyenv.run | bash
  fi

  log_info "pyenv installation completed; add init lines to shell profile"
  log_info "See https://github.com/pyenv/pyenv#installation for setup"
}

install_pyenv
