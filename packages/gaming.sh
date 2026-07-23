#!/usr/bin/env bash
set -euo pipefail

# Gaming runtime: performance/overlay tools + Proton manager.
# Vulkan is handled by installers/vulkan.sh (per-GPU vendor logic).
#
# On Arch, lib32-* packages need [multilib] enabled (handled in bootstrap/arch.sh).
install_gaming_stack() {
  install_package gamemode
  install_package mangohud
  if is_arch; then
    pkg_install lib32-gamemode
    pkg_install lib32-mangohud
    # protonup-qt: GUI for installing Proton-GE / community Proton builds.
    pkg_install protonup-qt
  elif is_debian_like; then
    # protonup-qt isn't packaged in apt; Flatpak (net.davidotek.pupgui2) is the
    # canonical distribution path. Left out here; install via Flatpak if needed.
    log_info "skipping protonup-qt on Debian/Ubuntu (use Flatpak: net.davidotek.pupgui2)"
  fi
}
