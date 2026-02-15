#!/usr/bin/env bash
set -euo pipefail

# Homelab-specific networking and secrets tools
HOMELAB_PACKAGES=(
  net-tools
  iproute2
  sops
)

install_homelab_packages() {
  install_packages "${HOMELAB_PACKAGES[@]}"
  # age is already in core.sh, no need to reinstall
}
