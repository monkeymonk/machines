#!/usr/bin/env bash
set -euo pipefail

# AI tooling for roles that need local models.
install_ai_stack() {
  install_package ollama
}
