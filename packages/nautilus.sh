#!/usr/bin/env bash
set -euo pipefail

# Nautilus file manager + extensions. The plugin pair routes to its installer
# because the Arch and Debian paths are quite different (AUR vs pip+apt).
install_nautilus_stack() {
  if ! is_gui_capable; then
    log_info "skipping nautilus (not a GUI host)"
    return 0
  fi
  install_package_with_mapping "nautilus"
  install_package nautilus-plugins
}
