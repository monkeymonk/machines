#!/usr/bin/env bash
set -euo pipefail

# Server role stays lean without desktop tooling.
server_role() {
  install_core_packages
  install_shell_stack
  install_dev_packages
}
