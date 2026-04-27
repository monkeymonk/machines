#!/usr/bin/env bash
set -euo pipefail

# Lean server role focused on security and essentials.
# install_core_packages is run by main() before the role.
server_role() {
  install_security_packages
  install_server_tools
  install_package docker
  install_package neovim
}
