#!/usr/bin/env bash
set -euo pipefail

install_oh_my_zsh() {
  local target_dir="$HOME/.oh-my-zsh"
  local dry_run="${DRY_RUN:-false}"
  log_info "Installing Oh My Zsh"
  if [[ -d "$target_dir" ]]; then
    log_info "Oh My Zsh already installed at $target_dir"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would clone Oh My Zsh into $target_dir (dry-run)"
    return 0
  fi

  git clone https://github.com/ohmyzsh/ohmyzsh.git "$target_dir"

  log_info "Skipping default zshrc template; manage dotfiles externally"
}

install_oh_my_zsh
