#!/usr/bin/env bash
set -euo pipefail

# Workstation role aggregates package groups and desktop apps.
WORKSTATION_DESKTOP_APPS=(
  google-chrome
  firefox
  brave-browser
  discord
  vlc
  junction
)

install_workstation_desktop_apps() {
  install_packages "${WORKSTATION_DESKTOP_APPS[@]}"
}

workstation_role() {
  install_core_packages
  install_shell_stack
  install_dev_packages
  install_ai_stack
  install_lazyvim_stack
  install_workstation_desktop_apps
  install_package nvm
  install_package pyenv
  install_package rustup
  install_package tmux
  install_package opencode
}
