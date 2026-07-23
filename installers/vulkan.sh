#!/usr/bin/env bash
set -euo pipefail

# Vulkan ICD loader + per-GPU vendor driver. Steam/Proton, DXVK, VKD3D, and the
# VR stack (Monado/Wivrn/OpenComposite) all depend on a working Vulkan runtime.
#
# Detects GPU vendor via /sys/class/drm/*/device/vendor and lspci as a fallback.
# Multiple ICDs coexist fine — useful on hybrid laptops.

has_amd_gpu_vulkan() {
  grep -qx 0x1002 /sys/class/drm/card*/device/vendor 2>/dev/null && return 0
  command_exists lspci && lspci | grep -qiE '(vga|3d|display).*(amd|ati|radeon)'
}

has_intel_gpu_vulkan() {
  grep -qx 0x8086 /sys/class/drm/card*/device/vendor 2>/dev/null && return 0
  command_exists lspci && lspci | grep -qiE '(vga|3d|display).*intel'
}

has_nvidia_gpu_vulkan() {
  grep -qx 0x10de /sys/class/drm/card*/device/vendor 2>/dev/null && return 0
  command_exists lspci && lspci | grep -qi nvidia
}

install_vulkan_stack() {
  local dry_run="${DRY_RUN:-false}"

  if is_macos; then
    log_warn "Vulkan on macOS goes through MoltenVK; not handled here"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install Vulkan loader + per-GPU drivers (dry-run)"
    return 0
  fi

  if is_arch; then
    _install_vulkan_arch
  elif is_debian_like; then
    _install_vulkan_debian
  else
    log_error "no Vulkan install path for $DISTRO"
    return 1
  fi
}

_install_vulkan_arch() {
  pkg_install vulkan-icd-loader
  pkg_install lib32-vulkan-icd-loader
  pkg_install vulkan-tools

  if has_amd_gpu_vulkan; then
    log_info "AMD GPU detected; installing RADV (mesa Vulkan)"
    pkg_install vulkan-radeon
    pkg_install lib32-vulkan-radeon
  fi
  if has_intel_gpu_vulkan; then
    log_info "Intel GPU detected; installing ANV (mesa Vulkan)"
    pkg_install vulkan-intel
    pkg_install lib32-vulkan-intel
  fi
  if has_nvidia_gpu_vulkan; then
    log_info "NVIDIA GPU detected; Vulkan ICD ships with the nvidia driver (installed separately)"
  fi
}

_install_vulkan_debian() {
  pkg_install vulkan-tools
  pkg_install libvulkan1
  if has_amd_gpu_vulkan || has_intel_gpu_vulkan; then
    pkg_install mesa-vulkan-drivers
  fi
  # 32-bit Vulkan on Debian requires `dpkg --add-architecture i386` and the
  # i386 mesa-vulkan-drivers package; this is non-trivial system surgery and
  # is left to the user — Steam's .deb pulls most of it in transitively.
}

install_vulkan_stack
