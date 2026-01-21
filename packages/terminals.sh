#!/usr/bin/env bash
set -euo pipefail

# Helper functions for optional terminal clients.
install_ghostty_stack() {
  install_package ghostty
}

install_wezterm_stack() {
  install_package wezterm
}
