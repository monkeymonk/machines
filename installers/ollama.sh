#!/usr/bin/env bash
set -euo pipefail

install_ollama() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists ollama; then
    log_info "Ollama already installed"
  else
    log_info "Installing Ollama"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install Ollama (dry-run)"
    else
      if is_macos; then
        if ! command_exists brew; then
          log_error "Homebrew not available; cannot install Ollama"
          return 1
        fi
        brew install ollama
      elif is_arch; then
        pkg_install ollama
      elif is_debian_like; then
        curl -fsSL https://ollama.com/install.sh | sh
      else
        log_error "Unsupported distro for Ollama install: $DISTRO"
        return 1
      fi
    fi
  fi

  if command_exists systemctl; then
    if ! systemctl is-active --quiet ollama; then
      if [[ "$dry_run" == true ]]; then
        log_info "Would enable Ollama systemd service (dry-run)"
      else
        sudo systemctl enable --now ollama
      fi
    fi
  fi

  if [[ "${OLLAMA_SKIP_MODELS:-false}" == true ]]; then
    log_info "Skipping Ollama model pulls"
    return 0
  fi

  local models=()
  if [[ -n "${OLLAMA_MODELS:-}" ]]; then
    read -r -a models <<<"$OLLAMA_MODELS"
  else
    models=(
      qwen2.5-coder:7b
      # qwen2.5-coder:32b
      deepseek-coder-v2:lite
      # starcoder2:15b
      # starcoder2:instruct
      # mistral-nemo:12b
      llama3.1:8b
      # llama3.1:70b
      # gemma2:27b
      # phi3.5
      # granite-code:8b
      # granite-code:20b
      # granite-code:34b
      # nomic-embed-text
      # mxbai-embed-large
      # bge-m3
    )
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would pull Ollama models: ${models[*]} (dry-run)"
    return 0
  fi

  if ! command_exists ollama; then
    log_error "Ollama is not available; cannot pull models"
    return 1
  fi

  local existing_models=""
  existing_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)

  for model in "${models[@]}"; do
    if printf '%s\n' "$existing_models" | grep -Fxq "$model"; then
      log_info "Ollama model already installed: $model"
    else
      log_info "Pulling Ollama model: $model"
      ollama pull "$model"
    fi
  done
}

install_ollama
