#!/usr/bin/env bash
set -euo pipefail

# Security and compliance packages.
# logwatch has no arch: override — it lives in AUR, so the auto path uses
# pkg_install_or_aur which falls through to paru.
SECURITY_PACKAGES=(
  "openssh-server,arch:openssh"
  "auditd,arch:audit"
  "logwatch"
)

# Debian-specific security packages
DEBIAN_SECURITY_PACKAGES=(
  unattended-upgrades
  apt-listchanges
)

install_security_packages() {
  install_package fail2ban
  install_package ufw
  for pkg in "${SECURITY_PACKAGES[@]}"; do
    install_package_with_mapping "$pkg"
  done

  if is_debian_like; then
    install_packages "${DEBIAN_SECURITY_PACKAGES[@]}"
  fi
}
