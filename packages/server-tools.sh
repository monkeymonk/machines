#!/usr/bin/env bash
set -euo pipefail

# Server management utilities
SERVER_TOOLS_PACKAGES=(
  ncdu
  rsync
)

install_server_tools() {
  install_packages "${SERVER_TOOLS_PACKAGES[@]}"
}
