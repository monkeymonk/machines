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

gaming_role() {
  install_core_packages
  install_shell_stack
  install_dev_packages
  install_gaming_desktop_apps
  install_package steam
  install_package nvidia-driver
}
