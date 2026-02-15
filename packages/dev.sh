#!/usr/bin/env bash
set -euo pipefail

# Additional tooling useful for development systems.
# Note: htop and jq are in core.sh, kept here for explicit dev role
DEV_PACKAGES=(htop jq)

install_dev_packages() {
  install_packages "${DEV_PACKAGES[@]}"
}
