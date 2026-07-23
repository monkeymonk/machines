#!/usr/bin/env bash
set -euo pipefail

install_oh_my_zsh() {
  local target_dir="$HOME/.oh-my-zsh"
  local custom_dir="${ZSH_CUSTOM:-$target_dir/custom}"
  local dry_run="${DRY_RUN:-false}"

  log_info "Installing Oh My Zsh"
  if [[ -d "$target_dir" ]]; then
    log_info "Oh My Zsh already installed at $target_dir"
  elif [[ "$dry_run" == true ]]; then
    log_info "Would clone Oh My Zsh into $target_dir (dry-run)"
  else
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$target_dir"
    log_info "Skipping default zshrc template; manage dotfiles externally"
  fi

  clone_zsh_custom_plugin() {
    local name="$1"
    local url="$2"
    local dest="$custom_dir/plugins/$name"
    if [[ -d "$dest" ]]; then
      log_info "$name already installed"
      return 0
    fi
    if [[ "$dry_run" == true ]]; then
      log_info "Would clone $name into $dest (dry-run)"
      return 0
    fi
    git clone --depth=1 "$url" "$dest"
  }

  clone_zsh_custom_plugin zsh-autosuggestions \
    https://github.com/zsh-users/zsh-autosuggestions
  clone_zsh_custom_plugin zsh-syntax-highlighting \
    https://github.com/zsh-users/zsh-syntax-highlighting
  clone_zsh_custom_plugin zsh-vi-mode \
    https://github.com/jeffreytse/zsh-vi-mode

  install_catppuccin_theme() {
    local themes_dir="$custom_dir/themes"
    local repo_dir="$themes_dir/catppuccin-zsh"
    if [[ ! -d "$repo_dir" ]]; then
      if [[ "$dry_run" == true ]]; then
        log_info "Would clone catppuccin-zsh theme into $repo_dir (dry-run)"
        return 0
      fi
      mkdir -p "$themes_dir"
      git clone --depth=1 https://github.com/JannoTjarks/catppuccin-zsh "$repo_dir"
    else
      log_info "catppuccin-zsh theme already cloned"
    fi
    if [[ "$dry_run" == true ]]; then
      log_info "Would link catppuccin theme files into $themes_dir (dry-run)"
      return 0
    fi
    ln -sfn "$repo_dir/catppuccin.zsh-theme" "$themes_dir/catppuccin.zsh-theme"
    ln -sfn "$repo_dir/catppuccin-flavors" "$themes_dir/catppuccin-flavors"
  }

  install_catppuccin_theme
}

install_oh_my_zsh
