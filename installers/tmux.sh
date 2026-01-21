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
      if command_exists pip3; then
        pip3 install --user tmuxp
      elif command_exists pip; then
        pip install --user tmuxp
      else
        log_error "pip not available; cannot install tmuxp"
        return 1
      fi
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

  local tmux_conf="$HOME/.tmux.conf"
  local marker="# >>> machines tmux plugins"
  if [[ -f "$tmux_conf" ]] && grep -q "$marker" "$tmux_conf"; then
    log_info "tmux plugin block already configured"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would add tmux plugin block to $tmux_conf (dry-run)"
    return 0
  fi

  if [[ -f "$tmux_conf" ]]; then
    log_info "Appending tmux plugin block to $tmux_conf"
  else
    log_info "Creating $tmux_conf with tmux plugin block"
  fi

  cat >>"$tmux_conf" <<'EOF'

# >>> machines tmux plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
run '~/.tmux/plugins/tpm/tpm'
# <<< machines tmux plugins
EOF
}

install_tmux
