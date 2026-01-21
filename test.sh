#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

ERRORS=0
WARNINGS=0

print_status() {
  local status="$1"
  local message="$2"
  case "$status" in
    pass) echo -e "${GREEN}[PASS]${NC} $message" ;;
    fail) echo -e "${RED}[FAIL]${NC} $message" ;;
    warn) echo -e "${YELLOW}[WARN]${NC} $message" ;;
    info) echo -e "[ -- ] $message" ;;
  esac
}

check_shellcheck() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    print_status warn "shellcheck not installed, skipping lint checks"
    return 0
  fi

  print_status info "Running shellcheck..."
  local files
  files=$(find "$SCRIPT_DIR" -name "*.sh" -type f)

  local failed=false
  for file in $files; do
    if shellcheck -x "$file" 2>/dev/null; then
      print_status pass "$(basename "$file")"
    else
      print_status fail "$(basename "$file")"
      failed=true
      ((ERRORS++))
    fi
  done

  if [[ "$failed" == false ]]; then
    print_status pass "All files passed shellcheck"
  fi
}

check_syntax() {
  print_status info "Checking bash syntax..."
  local files
  files=$(find "$SCRIPT_DIR" -name "*.sh" -type f)

  local failed=false
  for file in $files; do
    if bash -n "$file" 2>/dev/null; then
      print_status pass "$(basename "$file")"
    else
      print_status fail "$(basename "$file")"
      failed=true
      ((ERRORS++))
    fi
  done

  if [[ "$failed" == false ]]; then
    print_status pass "All files have valid syntax"
  fi
}

check_sourcing() {
  print_status info "Checking files can be sourced..."

  # Source lib files in order (they have dependencies)
  local lib_files=("log.sh" "os.sh" "pkg.sh")
  for file in "${lib_files[@]}"; do
    local path="$SCRIPT_DIR/lib/$file"
    if [[ -f "$path" ]]; then
      if (source "$path" 2>/dev/null); then
        print_status pass "lib/$file"
      else
        print_status fail "lib/$file"
        ((ERRORS++))
      fi
    fi
  done

  # Source packages (need lib first)
  for file in "$SCRIPT_DIR"/packages/*.sh; do
    if [[ -f "$file" ]]; then
      if (source "$SCRIPT_DIR/lib/log.sh" && source "$SCRIPT_DIR/lib/os.sh" && source "$SCRIPT_DIR/lib/pkg.sh" && source "$file" 2>/dev/null); then
        print_status pass "packages/$(basename "$file")"
      else
        print_status fail "packages/$(basename "$file")"
        ((ERRORS++))
      fi
    fi
  done
}

run_dry_run() {
  print_status info "Running install.sh --dry-run..."
  if "$SCRIPT_DIR/install.sh" --dry-run >/dev/null 2>&1; then
    print_status pass "Dry-run completed successfully"
  else
    print_status fail "Dry-run failed"
    ((ERRORS++))
  fi
}

main() {
  echo "========================================"
  echo "  machines test suite"
  echo "========================================"
  echo ""

  check_syntax
  echo ""
  check_shellcheck
  echo ""
  check_sourcing
  echo ""
  run_dry_run
  echo ""

  echo "========================================"
  if [[ $ERRORS -gt 0 ]]; then
    print_status fail "Tests completed with $ERRORS error(s)"
    exit 1
  else
    print_status pass "All tests passed"
    exit 0
  fi
}

main "$@"
