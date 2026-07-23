#!/usr/bin/env bash
set -euo pipefail

# Gaming workstation with graphics drivers, desktop apps, and Steam.
GAMING_DESKTOP_APPS=(
  google-chrome
  firefox
  brave-browser
  discord
  vlc
  junction
)

install_gaming_desktop_apps() {
  install_packages "${GAMING_DESKTOP_APPS[@]}"
}

# install_core_packages is run by main() before the role.
gaming_role() {
  install_shell_stack
  install_dev_packages
  install_gaming_desktop_apps

  install_sharing_stack            # avahi + nss-mdns (.local resolution, wivrn discovery)
  install_package vulkan           # vulkan loader + per-GPU ICD
  install_package nvidia-driver    # no-op on non-NVIDIA hardware
  install_package steam
  install_gaming_stack             # gamemode + mangohud + protonup-qt
  install_package vr-stack         # opencomposite + xrizer + wivrn (Arch-only)
}
