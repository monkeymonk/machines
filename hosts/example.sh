#!/usr/bin/env bash
# Template for host-specific overrides at hosts/$(hostname).sh.
# install.sh auto-loads the file matching the current hostname.
#
# Two integration points:
#   1. Set ROLE to override the default ("server"). The --role CLI flag
#      still wins over what's set here.
#   2. Define host_extras() to run after the role completes — typically the
#      desktop environment bundle and any per-machine tweaks.

ROLE="workstation"

host_extras() {
  # Use install_package <name> to trigger any installer or package — this is
  # what sources the installer file (and its bottom-of-file install_<name>
  # call). Calling install_<name> directly won't work unless the installer
  # has already been sourced this run.
  #
  # host_extras runs for every role, so gate per-role tweaks on $ROLE.
  #
  # Examples:
  #   if [[ "$ROLE" == "workstation" ]]; then
  #     install_package niri-stack    # cachyos desktop bundle
  #     install_package gnome-tweaks
  #   fi
  #   sudo systemctl enable foo       # ad-hoc tweaks
  :
}
