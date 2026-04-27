#!/usr/bin/env bash
set -euo pipefail

# CLI tooling beyond the absolute baseline in core.sh. Mostly handled by
# install_package_with_mapping (clean cross-distro names); mise/uv route to
# their installers because Debian needs upstream installers.
CLI_PACKAGES=(
  "fzf"
  "fd,debian:fd-find"
  "ripgrep"
  "bat"
  "zoxide"
  "eza,debian:eza"
  "jq"
  "yq"
)

install_cli_tools() {
  install_package mise   # installer dispatches per distro
  install_package uv     # installer dispatches per distro
  for pkg in "${CLI_PACKAGES[@]}"; do
    install_package_with_mapping "$pkg"
  done
}
