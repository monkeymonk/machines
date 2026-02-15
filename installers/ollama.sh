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
      # Ensure zstd is installed (required by ollama installer)
      if is_debian_like && ! command_exists zstd; then
        log_info "Installing zstd dependency for Ollama"
        pkg_install zstd
      fi

      if is_macos; then
        if ! command_exists brew; then
          log_error "Homebrew not available; cannot install Ollama"
          return 1
        fi
        brew install ollama
      elif is_arch; then
        pkg_install ollama
      elif is_debian_like; then
        # Retry logic for network issues
        local max_retries=3
        local retry=0
        while [[ $retry -lt $max_retries ]]; do
          if curl -fsSL https://ollama.com/install.sh | sh; then
            break
          else
            retry=$((retry + 1))
            if [[ $retry -lt $max_retries ]]; then
              log_warn "Ollama install failed (attempt $retry/$max_retries), retrying in 5s..."
              sleep 5
            else
              log_error "Ollama install failed after $max_retries attempts"
              return 1
            fi
          fi
        done
      else
        log_error "Unsupported distro for Ollama install: $DISTRO"
        return 1
      fi
    fi
  fi

  local service_available=false
  if command_exists systemctl; then
    if ! systemctl is-active --quiet ollama 2>/dev/null; then
      if [[ "$dry_run" == true ]]; then
        log_info "Would enable Ollama systemd service (dry-run)"
      else
        # Try to enable service, but don't fail if systemd isn't running (e.g., in containers)
        if sudo systemctl enable --now ollama 2>/dev/null; then
          log_info "Ollama service enabled"
          service_available=true
        else
          log_warn "Could not enable Ollama service (systemd may not be available)"
        fi
      fi
    else
      service_available=true
    fi
  fi

  # Allow environment variable to skip interactive prompt
  if [[ "${OLLAMA_SKIP_MODELS:-false}" == true ]]; then
    log_info "Skipping Ollama model pulls"
    return 0
  fi

  # Skip model pulls if service isn't available
  if [[ "$service_available" == false ]]; then
    log_info "Skipping Ollama model pulls (service not available)"
    return 0
  fi

  local models=()

  # Check if models specified via environment variable
  if [[ -n "${OLLAMA_MODELS:-}" ]]; then
    read -r -a models <<<"$OLLAMA_MODELS"
  elif [[ "$dry_run" == false ]] && [[ -t 0 ]]; then
    # Interactive mode: present menu of available models
    echo ""
    echo "Available Ollama models:"
    echo "  0) None (skip model installation)"
    echo "  1) qwen2.5-coder:7b - Coding model (recommended, ~4.7GB)"
    echo "  2) qwen2.5-coder:32b - Larger coding model (~19GB)"
    echo "  3) deepseek-coder-v2:lite - Lightweight coding model (~8.9GB)"
    echo "  4) llama3.1:8b - General purpose model (~4.7GB)"
    echo "  5) llama3.1:70b - Large general model (~40GB)"
    echo "  6) mistral-nemo:12b - Efficient general model (~7GB)"
    echo "  7) gemma2:27b - Google's model (~16GB)"
    echo "  8) nomic-embed-text - Text embeddings (~274MB)"
    echo ""
    echo "Enter numbers separated by spaces (e.g., '1 3 4' or '0' for none):"
    read -r selection

    # Parse selection
    local available_models=(
      ""  # 0 = none
      "qwen2.5-coder:7b"
      "qwen2.5-coder:32b"
      "deepseek-coder-v2:lite"
      "llama3.1:8b"
      "llama3.1:70b"
      "mistral-nemo:12b"
      "gemma2:27b"
      "nomic-embed-text"
    )

    for num in $selection; do
      if [[ "$num" == "0" ]]; then
        log_info "Skipping model installation"
        return 0
      elif [[ "$num" =~ ^[1-8]$ ]]; then
        models+=("${available_models[$num]}")
      else
        log_warn "Invalid selection: $num (skipping)"
      fi
    done

    if [[ ${#models[@]} -eq 0 ]]; then
      log_info "No models selected"
      return 0
    fi
  else
    # Non-interactive or dry-run: use minimal default models
    models=(
      qwen2.5-coder:7b
      deepseek-coder-v2:lite
      llama3.1:8b
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
