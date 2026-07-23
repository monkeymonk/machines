#!/usr/bin/env bash
set -euo pipefail

# VR runtime + OpenVR→OpenXR translation shims.
#
#   wivrn-dashboard  → Qt GUI for wivrn-server; pulls wivrn-server transitively.
#                      wivrn is a wireless OpenXR runtime that streams to
#                      standalone headsets (Quest, Pico) over the network.
#                      Needs mDNS (avahi-daemon) for headset discovery; the
#                      sharing stack covers that.
#   opencomposite-git → translates OpenVR (SteamVR) calls to OpenXR.
#   xrizer-git       → alternative OpenVR→OpenXR translator. Coexists with
#                      opencomposite; the active one is picked per-game via
#                      env vars (e.g. PRESSURE_VESSEL_FILESYSTEMS_RW).
#
# All three are AUR-only. Other distros: skip with a hint.
install_vr_stack() {
  if ! is_arch; then
    log_warn "VR stack (wivrn/opencomposite/xrizer) is AUR-only; no install path for $DISTRO"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install wivrn-dashboard, opencomposite-git, xrizer-git from AUR (dry-run)"
    return 0
  fi

  aur_install opencomposite-git
  aur_install xrizer-git
  aur_install wivrn-dashboard
}

install_vr_stack
