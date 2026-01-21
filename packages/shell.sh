#!/usr/bin/env bash
set -euo pipefail

# Shell tooling separated from core packages.
install_shell_stack() {
  install_package zsh
  install_package oh-my-zsh
}
