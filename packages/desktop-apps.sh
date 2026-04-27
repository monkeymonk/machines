#!/usr/bin/env bash
set -euo pipefail

# Desktop apps with clean cross-distro mappings. Apps needing apt-repo-add,
# .deb-from-upstream, snap, or build-from-source live in installers/.
DESKTOP_APPS=(
  "firefox"
  "filezilla"
  "mpv"
)

install_desktop_apps() {
  if ! is_gui_capable; then
    log_info "skipping desktop apps (not a GUI host)"
    return 0
  fi
  for pkg in "${DESKTOP_APPS[@]}"; do
    install_package_with_mapping "$pkg"
  done
}
