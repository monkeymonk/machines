#!/usr/bin/env bash
set -euo pipefail

# AI tooling for roles that need local models: ROCm GPU runtime + model
# runtimes (ollama, llama-cpp, llama-swap).
install_ai_stack() {
  install_package rocm      # GPU runtime layer; self-skips with no AMD GPU (safe on Intel/NVIDIA/macOS)
  install_package ollama
  install_package llama-cpp
  install_package llama-swap
}
