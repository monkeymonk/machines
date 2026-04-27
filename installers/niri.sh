#!/usr/bin/env bash
set -euo pipefail

# niri (https://github.com/YaLTeR/niri) — Wayland scrolling-tile compositor.

install_niri() {
  if ! is_display_host; then
    log_info "skipping niri (not a display host)"
    return 0
  fi
  if command_exists niri; then
    log_info "niri already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install niri (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install_or_aur niri
  elif is_debian_like; then
    if ! command_exists cargo; then
      log_info "rustup not present; installing"
      install_package rustup
      # shellcheck disable=SC1091
      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    fi
    sudo apt-get install -y \
      libwayland-dev libxkbcommon-dev libudev-dev libinput-dev \
      libgbm-dev libdrm-dev libsystemd-dev libdbus-1-dev libpango1.0-dev \
      libpipewire-0.3-dev libegl-dev libgles-dev libseat-dev pkg-config clang
    cargo install --locked --git https://github.com/YaLTeR/niri niri
  else
    log_error "no niri install path for $DISTRO"
    return 1
  fi
}

install_niri
