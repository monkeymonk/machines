#!/usr/bin/env bash
set -euo pipefail

# llama.cpp (https://github.com/ggerganov/llama.cpp). Vulkan backend on Linux,
# Metal on macOS via brew.

install_llama_cpp() {
  if command_exists llama-server || command_exists llama-cli; then
    log_info "llama.cpp already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install llama.cpp (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install llama.cpp-vulkan
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for llama.cpp on macOS"
      return 1
    fi
    brew install llama.cpp
  elif is_debian_like; then
    # llama.cpp's Vulkan backend needs glslc + spirv-tools + shaderc on top of
    # the Vulkan loader/headers from libvulkan-dev.
    sudo apt-get install -y \
      cmake build-essential git \
      glslang-tools libvulkan-dev \
      glslc spirv-tools libshaderc-dev || \
      log_warn "some llama.cpp build deps were not available; cmake configure may fail"
    local src
    src=$(mktemp -d)
    git clone --depth=1 https://github.com/ggerganov/llama.cpp "$src/llama.cpp"
    if ! (cd "$src/llama.cpp" &&
        cmake -B build -DGGML_VULKAN=ON &&
        cmake --build build -j"$(nproc)" &&
        sudo cmake --install build --prefix /usr/local); then
      log_warn "llama.cpp build failed; install manually if needed"
    fi
    rm -rf "$src"
  else
    log_error "no llama.cpp install path for $DISTRO"
    return 1
  fi
}

install_llama_cpp
