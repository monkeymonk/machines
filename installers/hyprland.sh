#!/usr/bin/env bash
set -euo pipefail

# Hyprland Desktop Environment Package Group Installer
# This installer is the entry point when using: ./install.sh --packages hyprland

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Source the hyprland package group
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../packages/hyprland.sh"

# Run the installation
install_hyprland_packages
