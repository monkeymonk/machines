#!/usr/bin/env bash
set -euo pipefail

# Lean server role focused on security and essentials
server_role() {
  install_core_packages
  install_security_packages
  install_server_tools
  install_package docker
  install_package neovim
}
