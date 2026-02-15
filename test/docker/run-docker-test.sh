#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-common.sh"

# Role mapping per distro
get_test_role() {
    local distro="$1"
    case "$distro" in
        ubuntu24) echo "workstation" ;;
        debian12) echo "server" ;;
        arch) echo "workstation" ;;
        *) echo "server" ;;
    esac
}

usage() {
    echo "Usage: $0 <distro>  where distro is ubuntu24|debian12|arch"
}

check_prerequisites() {
    local distro="$1"

    if ! command -v docker &> /dev/null; then
        log_test_error "Docker is not installed or not in PATH"
        exit 2
    fi

    if [ ! -f "Dockerfile.$distro" ]; then
        log_test_error "Dockerfile.$distro not found in current directory"
        exit 2
    fi
}

build_image() {
    local distro="$1"

    log_test_info "Building Docker image for $distro..."
    docker build -f "Dockerfile.$distro" -t "machines-test:$distro" . || return $?
}

run_tests() {
    local distro="$1"
    local role
    role=$(get_test_role "$distro")

    log_test_info "Running tests in container with role: $role"
    docker run --rm -v "$(pwd)/../..:/machines" "machines-test:$distro" bash -c "su - testuser -c 'cd /machines && export OLLAMA_SKIP_MODELS=true SKIP_CARGO_PACKAGES=true && ./test.sh && ./install.sh --role $role --dry-run && ./install.sh --role $role && command -v git zsh cargo ollama'" || return $?
}

cleanup() {
    local distro="$1"

    log_test_info "Cleanup..."
    # Containers are automatically removed with --rm flag
}

main() {
    local distro="$1"
    local role

    case "$distro" in
        ubuntu24|debian12|arch)
            ;;
        *)
            usage
            exit 1
            ;;
    esac

    role=$(get_test_role "$distro")
    check_prerequisites "$distro" || exit 2
    start_time=$(measure_time)
    build_image "$distro" || { log_test_fail "Build failed"; exit 1; }
    run_tests "$distro" || { log_test_fail "Tests failed"; exit 1; }
    cleanup "$distro"
    end_time=$(measure_time)
    duration=$(format_duration "$start_time" "$end_time")
    log_test_pass "$distro tests completed with role=$role in $duration"
}

[[ $# -eq 0 ]] && usage && exit 1

main "$1"
