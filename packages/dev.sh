#!/usr/bin/env bash
set -euo pipefail

# Additional tooling useful for development systems.
DEV_PACKAGES=(htop vim jq)

install_dev_packages() {
  install_packages "${DEV_PACKAGES[@]}"
}
