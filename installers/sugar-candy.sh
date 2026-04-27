#!/usr/bin/env bash
set -euo pipefail

# SDDM Sugar Candy theme.
#   Arch family : AUR sddm-sugar-candy-git
#   Debian/Ubuntu: git clone (it's QML+assets, no build), plus Qt graphical
#                  effects runtime dep.

_SUGAR_CANDY_DIR="/usr/share/sddm/themes/sugar-candy"
_SUGAR_CANDY_REPO="https://framagit.org/MarianArlt/sddm-sugar-candy.git"

install_sugar_candy_theme() {
  if ! is_display_host; then
    log_info "skipping sugar-candy (not a display host)"
    return 0
  fi
  if [[ -f "$_SUGAR_CANDY_DIR/theme.conf" ]]; then
    log_info "sugar-candy theme already present"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install sugar-candy theme (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install sddm-sugar-candy-git
  elif is_debian_like; then
    sudo apt-get install -y qml-module-qtgraphicaleffects sddm git
    sudo git clone --depth=1 "$_SUGAR_CANDY_REPO" "$_SUGAR_CANDY_DIR"
  else
    log_error "no sugar-candy install path for $DISTRO"
    return 1
  fi
}

install_sugar_candy_theme
