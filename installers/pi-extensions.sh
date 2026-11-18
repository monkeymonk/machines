#!/usr/bin/env bash
set -euo pipefail

# Extensions that close the capability gap between bare Pi and Oh My Pi (omp):
# LSP, an MCP client, subagents, a TODO tool, plan mode, and Docker sandboxing
# all ship built into omp, but Pi's minimal core gets them via community
# npm extensions instead. Installed with `pi install npm:<pkg>`, Pi's own
# package manager — distinct from the OS package manager this repo otherwise
# wraps, and it appends to ~/.pi/agent/settings.json's `packages` array.
#
# Requires installers/pi.sh (or an existing pi install) first.

PI_SETTINGS="$HOME/.pi/agent/settings.json"

# Core parity set: mirrors an omp built-in 1:1. Installed unconditionally.
PI_CORE_EXTENSIONS=(
  "npm:pi-lens"                            # LSP, linters, formatters, type-checking
  "npm:pi-mcp-adapter"                     # MCP client
  "npm:@tintinweb/pi-subagents"            # subagent delegation
  "npm:@juicesharp/rpiv-todo"              # todo overlay
  "npm:@juicesharp/rpiv-ask-user-question" # structured ask-user tool
  "npm:@narumitw/pi-plan-mode"             # read-only /plan mode
  "npm:@christianmoesl/pi-sbx"             # Docker sbx sandboxing
)

# Optional set: real capability, but either newer/single-maintainer with no
# long track record, or outside strict omp parity (a genuine enhancement omp
# itself doesn't have either). Confirmed interactively; skipped (with
# instructions) in non-interactive runs. Review the source before accepting --
# Pi extensions run with full system access.
#
# Considered and left out entirely (not in this array, add manually if wanted):
#   pi-browser-cdp-extension -- 79 downloads/month, redundant with the
#     chrome-devtools-mcp path pi-mcp-adapter already exposes.
#   @nicknisi/pi-handoff -- duplicates aic-packages' own prepare-handoff
#     skill at the prompt layer; personal-scoped package, 386 downloads/month.
#   @arhen/pi-core-skill-tool -- a system-prompt token-savings tweak (skill
#     catalog -> lazy tool), not a capability gap; 461 downloads/month.
#   pi-web-access -- already installed on this machine (web search/fetch/PDF/
#     video), predates this script; nothing to add here.
#   @pi-kaush/pi-better-read-edit -- CONFIRMED BROKEN: registers its own
#     "read"/"edit" tools, which fatally conflicts with pi-sbx (core, above)
#     wrapping the same two tool names for sandboxed execution. Pi refuses to
#     start with both installed ("Tool "read" conflicts with ..."). pi-sbx is
#     the higher-value, higher-adoption, core-parity match (omp's Docker
#     sandboxing); pi-better-read-edit lost the tiebreak. Do not add back
#     without dropping pi-sbx first.
PI_OPTIONAL_EXTENSIONS=(
  "npm:@nteract/pi|persistent Python REPL (ipykernel) -- closest match to omp's python/notebook tools; also installs the separate runtimed daemon it needs"
  "npm:pi-acp|ACP server adapter (spawns 'pi --mode rpc', bridges stdio JSON-RPC) for ACP editors like Zed"
  "npm:pi-memory|qmd-powered long-term memory + semantic search across sessions -- not an omp built-in, but popular (34k dl/mo) and well past prototype stage"
  "npm:pi-sessions|session search/indexing/auto-titling plus cross-session handoff and messaging -- partial answer to omp's collab/share, modest adoption (520 dl/mo)"
  "npm:pi-lazy-extensions|lazy-loads other extensions behind a proxy tool, worth it once you're running this many -- from the same trusted author as pi-web-access/pi-mcp-adapter"
)

NTERACT_PI_SPEC="npm:@nteract/pi"

pi_extension_installed() {
  local spec="$1"
  [[ -f "$PI_SETTINGS" ]] && grep -qF "\"$spec\"" "$PI_SETTINGS"
}

# @nteract/pi is inert without nteract's separate runtimed daemon (it's not
# an npm dependency -- it's a native binary the extension shells out to).
# Installed the same way as every other upstream curl installer in this repo
# (see installers/mise.sh, installers/opencode.sh): idempotent, official URL.
pi_install_nteract_runtimed() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists runtimed; then
    log_info "nteract runtimed daemon already installed"
    return 0
  fi
  if [[ "$dry_run" == true ]]; then
    log_info "Would install nteract runtimed daemon (dry-run)"
    return 0
  fi
  log_info "Installing nteract runtimed daemon (required by @nteract/pi)"
  curl -fsSL https://sh.nteract.io | bash
}

# Per-extension follow-up that npm alone can't express. Called after a spec
# is confirmed installed, whether freshly installed or already present.
pi_extension_post_install() {
  local spec="$1"
  if [[ "$spec" == "$NTERACT_PI_SPEC" ]]; then
    pi_install_nteract_runtimed
  fi
}

pi_install_extension() {
  local spec="$1"
  local dry_run="${DRY_RUN:-false}"

  if pi_extension_installed "$spec"; then
    log_info "$spec already installed"
    return 0
  fi
  if [[ "$dry_run" == true ]]; then
    log_info "Would run: pi install $spec (dry-run)"
    return 0
  fi
  log_info "Installing $spec"
  pi install "$spec"
}

pi_print_guided_setup() {
  local docker_status="MISSING -- run ./install.sh --packages docker"
  command_exists docker && docker_status="found"
  local runtimed_status="not needed (nteract not installed)"
  pi_extension_installed "$NTERACT_PI_SPEC" && {
    runtimed_status="MISSING -- run: curl -fsSL https://sh.nteract.io | bash"
    command_exists runtimed && runtimed_status="found"
  }

  log_info "----------------------------------------------------------------"
  log_info "pi extension setup done. Remaining manual steps:"
  log_info "  1. Docker (required by pi-sbx): $docker_status"
  log_info "  2. nteract runtimed daemon (required by @nteract/pi): $runtimed_status"
  log_info "  3. Browser automation (chrome-devtools-mcp) is wired by the"
  log_info "     aic-packages 'chromium' package, not by this repo -- check"
  log_info "     ~/.pi/agent/mcp.json has a chrome-devtools-mcp entry; if not,"
  log_info "     sync that repo (aic diff / aic sync)."
  log_info "  4. First real pi session in a new project: accept the"
  log_info "     project-trust prompt once (defaultProjectTrust=ask) --"
  log_info "     non-interactive 'pi -p' hangs on it until you do."
  log_info "  5. pi-acp (if installed): point your ACP client (e.g. Zed) at"
  log_info "     it -- that config lives in the editor, not here."
  log_info "  6. No sbx sandbox active for a directory is expected, not a"
  log_info "     bug: pi-sbx only routes tools through Docker sbx once you"
  log_info "     run 'sbx create ... shell .' in that project. pi/omp are"
  log_info "     not native sbx agents; see aic-packages' sbx-sandbox skill."
  log_info "----------------------------------------------------------------"
}

install_pi_extensions() {
  if ! command_exists pi; then
    log_error "pi not installed (run: ./install.sh --packages pi)"
    return 1
  fi

  for spec in "${PI_CORE_EXTENSIONS[@]}"; do
    pi_install_extension "$spec"
  done

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Skipping optional extensions and guided setup (dry-run)"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    log_info "Non-interactive mode: skipping optional extensions (Python REPL, ACP)"
    log_info "Run interactively to be prompted, or install manually:"
    for entry in "${PI_OPTIONAL_EXTENSIONS[@]}"; do
      log_info "  pi install ${entry%%|*}   # ${entry#*|}"
    done
  else
    for entry in "${PI_OPTIONAL_EXTENSIONS[@]}"; do
      local spec="${entry%%|*}"
      local desc="${entry#*|}"
      if pi_extension_installed "$spec"; then
        log_info "$spec already installed"
        pi_extension_post_install "$spec"
        continue
      fi
      local reply=""
      read -r -p "Install $spec ($desc)? [y/N] " reply
      if [[ "$reply" =~ ^[Yy]$ ]]; then
        pi_install_extension "$spec"
        pi_extension_post_install "$spec"
      else
        log_info "Skipped $spec"
      fi
    done
  fi

  pi_print_guided_setup
}

install_pi_extensions
