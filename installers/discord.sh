#!/usr/bin/env bash
set -euo pipefail

install_discord() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists discord; then
    log_info "Discord already installed"
    return 0
  fi

  log_info "Installing Discord"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Discord (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install Discord"
      return 1
    fi
    brew install --cask discord
  elif is_debian_like; then
    local tmp_deb
    tmp_deb=$(mktemp --suffix=.deb)
    curl -fsSL \
      "https://discord.com/api/download?platform=linux&format=deb" \
      -o "$tmp_deb"
    sudo dpkg -i "$tmp_deb" || sudo apt-get -f install -y
    rm -f "$tmp_deb"
  else
    pkg_install discord
  fi
}

install_discord
