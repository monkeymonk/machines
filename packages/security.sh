#!/usr/bin/env bash
set -euo pipefail

# Security and compliance packages
SECURITY_PACKAGES=(
  openssh-server
  auditd
  logwatch
)

# Debian-specific security packages
DEBIAN_SECURITY_PACKAGES=(
  unattended-upgrades
  apt-listchanges
)

install_security_packages() {
  install_package fail2ban
  install_package ufw
  install_packages "${SECURITY_PACKAGES[@]}"

  if is_debian_like; then
    install_packages "${DEBIAN_SECURITY_PACKAGES[@]}"
  fi
}
