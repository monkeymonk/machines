#!/usr/bin/env bash
set -euo pipefail

install_tmux() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Installing tmux stack"

  ensure_pip() {
    if command_exists pip3 || command_exists pip; then
      return 0
    fi

    if is_debian_like; then
      pkg_install python3-pip
    elif is_arch; then
      pkg_install python-pip
    elif is_macos; then
      if ! command_exists brew; then
        log_error "Homebrew not available; cannot install python for tmuxp"
        return 1
      fi
      brew install python
    else
      log_error "Unsupported distro for tmuxp install"
      return 1
    fi
  }

  pip_user_install() {
    local pkg="$1"
    local pip_cmd
    if command_exists pip3; then
      pip_cmd=pip3
    elif command_exists pip; then
      pip_cmd=pip
    else
      log_error "pip not available; cannot install $pkg"
      return 1
    fi
    if ! "$pip_cmd" install --user "$pkg" 2>/dev/null; then
      "$pip_cmd" install --user --break-system-packages "$pkg"
    fi
  }

  if command_exists tmux; then
    log_info "tmux already installed"
  else
    if [[ "$dry_run" == true ]]; then
      log_info "Would install tmux (dry-run)"
    else
      if is_macos; then
        if ! command_exists brew; then
          log_error "Homebrew not available; cannot install tmux"
          return 1
        fi
        brew install tmux
      else
        pkg_install tmux
      fi
    fi
  fi

  if command_exists tmuxp; then
    log_info "tmuxp already installed"
  else
    if [[ "$dry_run" == true ]]; then
      log_info "Would install tmuxp via pip (dry-run)"
    else
      ensure_pip
      pip_user_install tmuxp
    fi
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    log_info "TPM already installed"
  elif [[ "$dry_run" == true ]]; then
    log_info "Would clone TPM into $tpm_dir (dry-run)"
  else
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

install_tmux
