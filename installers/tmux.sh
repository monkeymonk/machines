#!/usr/bin/env bash
set -euo pipefail

install_tmux() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Installing tmux stack"

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

  # tmuxp: prefer native package (pacman/apt/brew); fall back to `uv tool` so
  # we don't drag pip + PEP 668 workarounds onto fresh systems.
  if command_exists tmuxp; then
    log_info "tmuxp already installed"
  elif [[ "$dry_run" == true ]]; then
    log_info "Would install tmuxp (dry-run)"
  else
    install_tmuxp_native_or_uv
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    log_info "TPM already installed"
  elif [[ "$dry_run" == true ]]; then
    log_info "Would clone TPM into $tpm_dir (dry-run)"
  else
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  # workmux: git worktrees + tmux windows for parallel agents (cargo crate).
  # shellcheck disable=SC1091
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  if command_exists workmux; then
    log_info "workmux already installed"
  elif ! command_exists cargo; then
    log_warn "cargo not available; skipping workmux (needs rustup/core packages first)"
  elif [[ "$dry_run" == true ]]; then
    log_info "Would install workmux via cargo (dry-run)"
  else
    cargo install workmux
  fi
}

install_tmuxp_native_or_uv() {
  if is_macos; then
    if command_exists brew; then
      brew install tmuxp && return 0
    fi
  elif is_arch || is_debian_like; then
    if pkg_install tmuxp; then
      return 0
    fi
    log_warn "native tmuxp install failed, falling back to uv"
  fi

  if ! command_exists uv; then
    log_info "uv missing; installing it first"
    install_package uv
  fi
  if ! command_exists uv; then
    log_error "uv unavailable; cannot install tmuxp"
    return 1
  fi
  log_info "Installing tmuxp via uv tool"
  uv tool install tmuxp
}

install_tmux
