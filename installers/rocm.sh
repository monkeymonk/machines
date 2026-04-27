#!/usr/bin/env bash
set -euo pipefail

# ROCm runtime + HIP for AMD GPUs. Skipped if no AMD GPU is present.
#
# Strix Point (Radeon 890M / 880M, gfx1150) isn't in ROCm's officially
# supported list yet — runtime/plugins/amdgpu.sh exports
# HSA_OVERRIDE_GFX_VERSION=11.0.0 to claim gfx1100 so HIP binaries run.
# llama.cpp here uses Vulkan; ROCm mainly benefits PyTorch / ONNX / rocm-smi.

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
    if rocminfo >/dev/null 2>&1; then
      log_info "rocminfo: GPU detected by ROCm"
    else
      log_warn "rocminfo failed — group changes take effect at next login"
    fi
  fi
}

install_rocm
