#!/usr/bin/env bash
set -euo pipefail

# mDNS / network discovery: Avahi daemon + NSS module. Needed for printer
# discovery, .local hostname resolution, and Wivrn's headset pairing.
install_sharing_stack() {
  install_package avahi
  install_package nss-mdns
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would enable avahi-daemon.service (dry-run)"
    return 0
  fi
  enable_system_unit avahi-daemon.service
}
