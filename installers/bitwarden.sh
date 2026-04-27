#!/usr/bin/env bash
set -euo pipefail

# Bitwarden desktop client.

install_bitwarden() {
  if ! is_gui_capable; then
    log_info "skipping bitwarden (not a GUI host)"
    return 0
  fi
  if command_exists bitwarden; then
    log_info "bitwarden already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install bitwarden (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install bitwarden
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for bitwarden on macOS"
      return 1
    fi
    brew install --cask bitwarden
  elif is_debian_like; then
    if command_exists snap; then
      sudo snap install bitwarden
    else
      log_info "snap not available; falling back to upstream .deb"
      local arch tag url
      arch=$(dpkg --print-architecture)
      tag=$(curl -fsSL https://api.github.com/repos/bitwarden/clients/releases |
        grep -oP '"tag_name"\s*:\s*"\Kdesktop-v[^"]+' | head -1)
      url="https://github.com/bitwarden/clients/releases/download/${tag}/Bitwarden-${tag#desktop-v}-${arch}.deb"
      download_and_install_deb "$url"
    fi
  else
    log_error "no bitwarden install path for $DISTRO"
    return 1
  fi
}

install_bitwarden
