#!/usr/bin/env bash
set -euo pipefail

# Environment variables with defaults
TEST_DISTRO="${TEST_DISTRO:-unknown}"
TEST_ROLE="${TEST_ROLE:-server}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

setup_machines_repo() {
    log "Setting up machines repository"

    # Copy repo from 2 levels up from Vagrantfile location
    mkdir -p /home/vagrant/machines
    cp -r /vagrant/../../. /home/vagrant/machines/ 2>/dev/null || true
    chown -R vagrant:vagrant /home/vagrant/machines

    # Verify repo copied
    if [[ ! -f /home/vagrant/machines/install.sh ]]; then
        log "ERROR: install.sh not found in /home/vagrant/machines"
        return 1
    fi

    log "Repository setup complete"
}

run_installation() {
    log "Running installation with role: $TEST_ROLE"

    cd /home/vagrant/machines
    ./install.sh --role "$TEST_ROLE" 2>&1 | tee /tmp/install.log
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log "ERROR: Installation failed with exit code $exit_code"
        log "Last 20 lines of log:"
        tail -20 /tmp/install.log
        return 1
    fi

    log "Installation completed successfully"
}

verify_installation() {
    log "Verifying installation"

    local missing=0

    for cmd in git zsh bat cargo; do
        if ! command -v "$cmd" &>/dev/null; then
            log "ERROR: $cmd not found"
            missing=$((missing + 1))
        else
            log "✓ $cmd found"
        fi
    done

    # Workstation-specific checks
    if [[ "$TEST_ROLE" == "workstation" ]]; then
        if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
            log "✓ Hyprland session file found"
        else
            log "WARNING: Hyprland session file not found (may not be installed)"
        fi
    fi

    if [[ $missing -gt 0 ]]; then
        log "ERROR: $missing required commands missing"
        return 1
    fi

    log "Verification passed"
}

test_idempotency() {
    log "Testing idempotency (second run)"

    cd /home/vagrant/machines
    ./install.sh --role "$TEST_ROLE" 2>&1 | tee /tmp/install-second.log
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log "ERROR: Second run failed with exit code $exit_code"
        return 1
    fi

    log "Idempotency test passed"
}

collect_results() {
    log "Collecting test results"

    local results_dir="/vagrant/test-results/full/$TEST_DISTRO"
    mkdir -p "$results_dir"

    # Copy logs
    cp /tmp/install.log "$results_dir/" 2>/dev/null || true
    cp /tmp/install-second.log "$results_dir/" 2>/dev/null || true

    # Generate package list
    if command -v dpkg &>/dev/null; then
        dpkg -l > "$results_dir/packages.txt"
    elif command -v pacman &>/dev/null; then
        pacman -Q > "$results_dir/packages.txt"
    fi

    # System info
    systemctl list-units --state=running > "$results_dir/services.txt" 2>/dev/null || true

    log "Results collected to $results_dir"
}

main() {
    log "=== Provisioning $TEST_DISTRO for $TEST_ROLE testing ==="

    setup_machines_repo || exit 1
    run_installation || exit 1
    verify_installation || exit 1
    test_idempotency || exit 1
    collect_results || exit 1

    log "=== Provisioning completed successfully ==="
}

main "$@"
