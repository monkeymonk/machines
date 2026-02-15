#!/usr/bin/env bash
set -euo pipefail

# Homelab role extends server with additional networking/secrets tools
homelab_role() {
  # Run full server setup
  server_role

  # Add homelab-specific packages
  install_homelab_packages
}
