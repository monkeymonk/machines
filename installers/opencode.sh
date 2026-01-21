#!/usr/bin/env bash
set -euo pipefail

install_opencode() {
  local dry_run="${DRY_RUN:-false}"

  if ! command_exists opencode; then
    log_info "Installing OpenCode"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install OpenCode via install script (dry-run)"
    else
      curl -fsSL https://opencode.ai/install | bash
    fi
  else
    log_info "OpenCode already installed"
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Skipping oh-my-opencode setup (dry-run)"
    return 0
  fi

  local installer_cmd=""
  if command_exists bunx; then
    installer_cmd="bunx oh-my-opencode install"
  elif command_exists npx; then
    installer_cmd="npx oh-my-opencode install"
  else
    log_error "bunx or npx is required to install oh-my-opencode"
    return 1
  fi

  local claude=""
  local chatgpt=""
  local gemini=""
  local copilot=""
  local answer=""

  printf "Do you have a Claude Pro/Max subscription? (yes/no): "
  read -r answer
  if [[ "$answer" == "yes" ]]; then
    printf "Are you on max20 (20x mode)? (yes/no): "
    read -r answer
    if [[ "$answer" == "yes" ]]; then
      claude="max20"
    else
      claude="yes"
    fi
  else
    claude="no"
  fi

  printf "Do you have a ChatGPT subscription? (yes/no): "
  read -r answer
  if [[ "$answer" == "yes" ]]; then
    chatgpt="yes"
  else
    chatgpt="no"
  fi

  printf "Will you integrate Gemini models? (yes/no): "
  read -r answer
  if [[ "$answer" == "yes" ]]; then
    gemini="yes"
  else
    gemini="no"
  fi

  printf "Do you have a GitHub Copilot subscription? (yes/no): "
  read -r answer
  if [[ "$answer" == "yes" ]]; then
    copilot="yes"
  else
    copilot="no"
  fi

  log_info "Running oh-my-opencode installer"
  $installer_cmd \
    --no-tui \
    --claude="$claude" \
    --chatgpt="$chatgpt" \
    --gemini="$gemini" \
    --copilot="$copilot"
}

install_opencode
