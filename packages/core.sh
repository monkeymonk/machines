#!/usr/bin/env bash
set -euo pipefail

# Core packages needed before dotfiles can run.
CORE_PACKAGES=(git curl fzf ripgrep fd)

install_core_packages() {
  install_packages "${CORE_PACKAGES[@]}"
}
