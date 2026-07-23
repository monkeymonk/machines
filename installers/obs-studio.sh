#!/usr/bin/env bash
set -euo pipefail

# OBS Studio (https://obsproject.com) — screen recording & streaming.
#
# Wayland-first setup for the Framework 13 / Ryzen AI HX 370 (Radeon 890M) on
# CachyOS + Niri:
#   - Capture goes through PipeWire + xdg-desktop-portal (wlroots → gtk backend).
#     Use the "Screen Capture (PipeWire)" source, never the X11 sources.
#   - Hardware encode via VAAPI on the AMD iGPU (libva-mesa-driver + mesa).
#   - Virtual camera via v4l2loopback so Zoom/Meet/Discord can use OBS as a cam.
#
# Plugins (AUR, Arch-only) mirror the personal workflow: Move Transition,
# Input Overlay, Source Record, Teleport.
#
# PipeWire/WirePlumber themselves are assumed present (CachyOS default); this
# installer only adds the capture/encode/virtual-cam pieces OBS needs.
#
# Post-install (manual):
#   1. Restart the session so the desktop portal picks up OBS.
#   2. Settings → Output (Advanced) → Recording: FFmpeg VAAPI H.264, MKV, CQ 18-22.
#   3. Add a "Screen Capture (PipeWire)" source and pick the monitor via the portal.
#   4. Verify VAAPI with `vainfo` (AMD GPU should be listed).

# Official-repo packages: OBS core, Wayland portal, VAAPI stack, vainfo tool.
_OBS_CORE_PKGS=(
  obs-studio
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  libva-mesa-driver
  mesa
  libva-utils
)

# AUR plugins (Arch-only). Installed best-effort — an AUR build break must not
# abort the rest of the install.
_OBS_AUR_PLUGINS=(
  obs-move-transition
  obs-input-overlay
  obs-source-record
  obs-teleport
)

# v4l2loopback options so the OBS virtual camera advertises exclusive_caps=1,
# which browsers (Chrome/Meet) require to see it as a webcam.
_OBS_MODPROBE_CONF='/etc/modprobe.d/v4l2loopback-obs.conf'
_OBS_MODPROBE_BODY='options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1'
_OBS_MODLOAD_CONF='/etc/modules-load.d/v4l2loopback.conf'

# Idempotently write a root-owned config file (mode 644). tee, not the sysd
# helpers, because those are for 755 scripts / systemd units.
_obs_write_conf() {
  local path="$1" body="$2"
  if sudo test -f "$path" && [[ "$(sudo cat "$path")" == "$body" ]]; then
    log_debug "$path already up to date"
    return 0
  fi
  printf '%s\n' "$body" | sudo tee "$path" >/dev/null
  log_info "wrote $path"
}

# Virtual camera: dkms module + modprobe options + autoload. Non-fatal: a dkms
# build failure (missing kernel headers) warns instead of killing the install.
_obs_install_virtual_camera() {
  if ! pkg_install_or_aur v4l2loopback-dkms; then
    log_warn "v4l2loopback-dkms failed (kernel headers missing?); virtual camera skipped"
    return 0
  fi
  _obs_write_conf "$_OBS_MODPROBE_CONF" "$_OBS_MODPROBE_BODY"
  _obs_write_conf "$_OBS_MODLOAD_CONF" "v4l2loopback"
  if ! lsmod | grep -q '^v4l2loopback'; then
    sudo modprobe v4l2loopback || \
      log_warn "could not load v4l2loopback now; it will load on next boot"
  fi
}

install_obs_studio() {
  if ! is_gui_capable; then
    log_info "skipping obs-studio (not a GUI host)"
    return 0
  fi

  if command_exists obs; then
    log_info "OBS Studio already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install OBS Studio + portal + VAAPI + virtual camera (dry-run)"
    return 0
  fi

  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install OBS Studio"
      return 1
    fi
    brew install --cask obs
    return 0
  fi

  if is_debian_like; then
    sudo apt-get install -y \
      obs-studio xdg-desktop-portal xdg-desktop-portal-gtk \
      mesa-va-drivers vainfo v4l2loopback-dkms
    _obs_write_conf "$_OBS_MODPROBE_CONF" "$_OBS_MODPROBE_BODY"
    _obs_write_conf "$_OBS_MODLOAD_CONF" "v4l2loopback"
    return 0
  fi

  if ! is_arch; then
    log_error "no OBS Studio install path for $DISTRO"
    return 1
  fi

  # Arch / CachyOS: core stack from official repos.
  for pkg in "${_OBS_CORE_PKGS[@]}"; do
    pkg_install_or_aur "$pkg"
  done

  _obs_install_virtual_camera

  # AUR plugins — best-effort, one failure must not abort the others.
  for plugin in "${_OBS_AUR_PLUGINS[@]}"; do
    pkg_install_or_aur "$plugin" || log_warn "failed to install OBS plugin $plugin (continuing)"
  done

  log_info "OBS Studio installed — restart your session, then use the Screen Capture (PipeWire) source"
}

install_obs_studio
