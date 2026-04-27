#!/usr/bin/env bash
set -euo pipefail

# Workstation role: DE-agnostic composition. The desktop environment
# (niri-stack, gnome, etc.) is invoked from per-host files, not here.
# install_core_packages is run by main() before the role.
workstation_role() {
  install_shell_stack
  install_dev_packages
  install_cli_tools
  install_ai_stack

  install_desktop_apps              # firefox, filezilla, mpv (gui_capable)
  install_package brave-browser
  install_package google-chrome
  install_package discord
  install_package bitwarden
  install_package junction
  install_package ghostty

  install_wayland_utils             # cliphist + wl-clipboard + grim + slurp
  install_nautilus_stack            # nautilus + plugins

  install_package neovim
  install_package tmux
  install_package opencode

  install_package docker            # group + service via installers/docker.sh
}
