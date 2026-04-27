#!/usr/bin/env bash
set -euo pipefail

# Nautilus extensions: copy-path + open-any-terminal.

install_nautilus_plugins() {
  if ! is_gui_capable; then
    log_info "skipping nautilus plugins (not a GUI host)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install nautilus plugins (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install nautilus-copy-path
    aur_install nautilus-open-any-terminal
  elif is_debian_like; then
    sudo apt-get install -y python3-nautilus python3-pip
    pip install --user --break-system-packages nautilus-open-any-terminal || \
      pip install --user nautilus-open-any-terminal
    if command_exists glib-compile-schemas; then
      glib-compile-schemas "$HOME/.local/share/glib-2.0/schemas/" 2>/dev/null || true
    fi
    log_warn "nautilus-copy-path has no apt package; clone manually if needed (https://github.com/ronen25/nautilus-copy-path)"
  else
    log_error "no nautilus-plugins install path for $DISTRO"
    return 1
  fi
}

install_nautilus_plugins
