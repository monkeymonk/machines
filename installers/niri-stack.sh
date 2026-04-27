#!/usr/bin/env bash
set -euo pipefail

# Composes the full niri-based desktop:
#   niri compositor + noctalia shell + sddm + sugar-candy theme + bg rotator
#   + vicinae launcher.

install_niri_stack() {
  if ! is_display_host; then
    log_info "skipping niri-stack (not a display host)"
    return 0
  fi

  install_package niri        # routes to installers/niri.sh
  install_package noctalia    # routes to installers/noctalia.sh
  if is_arch; then
    pkg_install sddm
  elif is_debian_like; then
    sudo apt-get install -y sddm
  fi
  install_package sugar-candy
  install_package sddm-bg
  install_package vicinae

  if command_exists systemctl && [[ "${DRY_RUN:-false}" != true ]]; then
    enable_system_unit sddm.service
  fi
}

install_niri_stack
