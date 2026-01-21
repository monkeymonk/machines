#!/usr/bin/env bash
set -euo pipefail

install_google_chrome() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists google-chrome; then
    log_info "Google Chrome already installed"
    return 0
  fi

  log_info "Installing Google Chrome"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Google Chrome (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install Google Chrome"
      return 1
    fi
    brew install --cask google-chrome
  elif is_debian_like; then
    local tmp_deb
    tmp_deb=$(mktemp --suffix=.deb)
    curl -fsSL \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      -o "$tmp_deb"
    sudo dpkg -i "$tmp_deb" || sudo apt-get -f install -y
    rm -f "$tmp_deb"
  elif is_arch; then
    if command_exists yay; then
      yay -S --needed google-chrome
    elif command_exists paru; then
      paru -S --needed google-chrome
    else
      log_warn "No AUR helper found; install Google Chrome manually"
    fi
  else
    pkg_install google-chrome
  fi
}

install_google_chrome
