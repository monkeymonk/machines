#!/usr/bin/env bash
set -euo pipefail

# Wayland-side utilities: clipboard, screen capture. cliphist routes to its
# installer because Debian stable may not package it.
WAYLAND_PACKAGES=(
  "wl-clipboard"
  "grim"
  "slurp"
)

install_wayland_utils() {
  if ! is_display_host; then
    log_info "skipping wayland utils (not a display host)"
    return 0
  fi
  install_package cliphist
  for pkg in "${WAYLAND_PACKAGES[@]}"; do
    install_package_with_mapping "$pkg"
  done
}
