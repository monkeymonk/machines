#!/usr/bin/env bash
set -euo pipefail

# Noctalia: a quickshell-based Wayland desktop config used with niri.
# On CachyOS, the cachyos-niri-noctalia meta-package handles everything.
# Elsewhere we install quickshell + clone the noctalia config repo.

_NOCTALIA_REPO="https://github.com/noctalia-dev/noctalia-shell.git"
_NOCTALIA_DEST="$HOME/.config/quickshell/noctalia-shell"

install_noctalia() {
  if ! is_display_host; then
    log_info "skipping noctalia (not a display host)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install noctalia (dry-run)"
    return 0
  fi

  if is_cachyos; then
    pkg_install cachyos-niri-noctalia
    return 0
  fi

  if is_arch; then
    pkg_install_or_aur quickshell
  elif is_debian_like; then
    if ! command_exists qs; then
      log_warn "quickshell not packaged in apt; build from source — see https://quickshell.outfoxxed.me"
      return 1
    fi
  fi

  if [[ -d "$_NOCTALIA_DEST/.git" ]]; then
    log_info "updating noctalia config"
    git -C "$_NOCTALIA_DEST" pull --ff-only
  else
    mkdir -p "$(dirname "$_NOCTALIA_DEST")"
    git clone --depth=1 "$_NOCTALIA_REPO" "$_NOCTALIA_DEST"
  fi
}

install_noctalia
