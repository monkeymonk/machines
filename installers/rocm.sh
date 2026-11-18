#!/usr/bin/env bash
set -euo pipefail

# ROCm runtime + HIP for AMD GPUs. Skipped if no AMD GPU is present.
#
# Strix Point (Radeon 890M, gfx1150) is officially supported as of ROCm
# 7.14.0 and 10.1.0 (AMD's compatibility matrix lists it under RDNA 3.5).
# No GFX-version override is needed on this hardware; only introduce one in
# response to a demonstrated, reproduced failure, not pre-emptively.
#
# llama.cpp and Ollama here run on their Vulkan builds and don't need ROCm;
# containerized PyTorch workloads bring their own ROCm userspace in the
# image. Host ROCm mainly buys HIP/OpenCL for host-side work plus rocminfo
# for diagnostics.

has_amd_gpu() {
  if command_exists lspci; then
    lspci | grep -qiE 'vga.*(amd|ati|radeon)|display.*(amd|ati|radeon)|3d.*(amd|ati|radeon)'
    return $?
  fi
  # Fallback: PCI vendor 0x1002 = AMD
  grep -qx 0x1002 /sys/class/drm/card*/device/vendor 2>/dev/null
}

install_rocm() {
  log_info "Checking for AMD GPU before installing ROCm"
  if ! has_amd_gpu; then
    log_info "No AMD GPU detected; skipping ROCm installation"
    return 0
  fi

  local dry_run="${DRY_RUN:-false}"

  if is_macos; then
    log_warn "ROCm is not supported on macOS; skipping"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install ROCm runtime, OpenCL, rocminfo (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install rocm-hip-runtime
    pkg_install rocm-opencl-runtime
    pkg_install rocminfo
  elif is_debian_like; then
    # AMD ships its own apt repo (repo.radeon.com) with a versioned key and
    # an `amdgpu-install` helper. Bootstrapping it cleanly is its own
    # installer — flag it loudly rather than half-doing it here.
    log_warn "ROCm on Debian/Ubuntu requires AMD's apt repo (https://repo.radeon.com)."
    log_warn "Add the repo + run amdgpu-install manually, then re-run."
    return 0
  else
    log_error "no ROCm install path for $DISTRO"
    return 1
  fi

  # /dev/kfd and /dev/dri/renderD* are gated by the render + video groups.
  add_user_to_group render
  add_user_to_group video

  if command_exists rocminfo; then
    # `id -nG` with no argument reports the groups active in *this* process;
    # passing a username re-reads the group database, which add_user_to_group
    # has just updated. Only the former can tell whether the new membership
    # is live yet, which is the whole point of the check.
    local session_groups
    session_groups="$(id -nG 2>/dev/null | tr ' ' '\n')"

    if ! grep -qx render <<<"$session_groups" || ! grep -qx video <<<"$session_groups"; then
      log_warn "render/video membership is not active in this session yet; log out and back in, then re-check rocminfo"
    elif rocminfo 2>/dev/null | grep -q 'Device Type:.*GPU'; then
      log_info "rocminfo: GPU detected by ROCm"
    else
      log_warn "rocminfo ran but reported no GPU agent; check the amdgpu driver (dmesg), not group membership"
    fi
  fi
}

install_rocm
