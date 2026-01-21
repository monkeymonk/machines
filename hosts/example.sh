#!/usr/bin/env bash
# Example host-specific override file.
# Copy this file to hosts/$(hostname).sh to customize a specific machine.
#
# This file is sourced after the role installation completes, so you have
# access to all helper functions (install_package, log_info, etc.).

# Example: Install additional packages for this host
# install_package "some-tool"

# Example: Run custom setup commands
# if [[ "$DRY_RUN" != true ]]; then
#   log_info "Running custom setup for $(hostname)"
# fi
