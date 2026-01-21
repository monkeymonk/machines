#!/usr/bin/env bash
set -euo pipefail

install_brave_browser() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists brave-browser; then
    log_info "Brave Browser already installed"
    return 0
  fi

  log_info "Installing Brave Browser"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Brave Browser (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install Brave Browser"
      return 1
    fi
    brew install --cask brave-browser
  elif is_debian_like; then
    pkg_install curl
    pkg_install gnupg
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg |
      sudo tee /usr/share/keyrings/brave-browser-archive-keyring.gpg >/dev/null
    echo \
      "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
      https://brave-browser-apt-release.s3.brave.com/ stable main" |
      sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
    pkg_update
    pkg_install brave-browser
  elif is_arch; then
    if command_exists yay; then
      yay -S --needed brave-browser
    elif command_exists paru; then
      paru -S --needed brave-browser
    else
      log_warn "No AUR helper found; install Brave Browser manually"
    fi
  else
    pkg_install brave-browser
  fi
}

install_brave_browser
