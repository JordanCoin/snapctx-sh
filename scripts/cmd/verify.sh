#!/usr/bin/env bash
# scripts/cmd/verify.sh - Context Engineering Revolution Self-test
set -euo pipefail

# Source libraries using a robust path
# shellcheck source=../lib/log.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
# shellcheck source=../lib/validation.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"

# The main script to test, located at the project root
SNAPCTX_CMD="$(dirname "${BASH_SOURCE[0]}")/../../universal-toolkit.sh"

log_header "CONTEXT ENGINEERING REVOLUTION - VERIFICATION"

# Test cases: command and arguments
TEST_CASES=(
  "cheatsheet"
  "cheatsheet --json"
  "analyze"
  "analyze --json"
  "health"
  "health --json"
  "spellcheck"
  "spellcheck --json"
  "cross-platform"
  "cross-platform --json"
  "install-deps --check-only"
  "help"
  "version"
)

ALL_PASS=true

# Temporary log file for stderr
STDERR_LOG=$(mktemp)
# Cleanup trap to remove the temp file on exit
trap 'rm -f "$STDERR_LOG"' EXIT

# Change to project root to run tests
pushd "$(dirname "${BASH_SOURCE[0]}")/../../" > /dev/null

for args in "${TEST_CASES[@]}"; do
  log_info "Running: $SNAPCTX_CMD $args"
  # Pass the arguments exactly as they are in the TEST_CASES array
  # Note: we use "bash" to run the script to ensure it works in various environments
  if bash "$SNAPCTX_CMD" $args > /dev/null 2> "$STDERR_LOG"; then
    log_success "  PASS: $args"
  else
    log_error "  FAIL: $args"
    if [[ -s "$STDERR_LOG" ]]; then
      log_error "    Stderr: $(cat "$STDERR_LOG")"
    else
      log_error "    Stderr: (empty)"
    fi
    ALL_PASS=false
  fi
done

# Return to the original directory
popd > /dev/null

# Additional context engineering validation tests
log_header "CONTEXT ENGINEERING VALIDATION"

# Test schema validation
log_info "Testing schema validation..."
TEMP_CTX="/tmp/test_ctx.json"
bash "$SNAPCTX_CMD" analyze --json > "$TEMP_CTX" 2>/dev/null

if validate_ctx_schema "$TEMP_CTX"; then
  log_success "  PASS: Schema validation"
else
  log_error "  FAIL: Schema validation"
  ALL_PASS=false
fi

# Test context quality metrics
log_info "Testing context quality metrics..."
if validate_context_quality "$TEMP_CTX" 0.5; then
  log_success "  PASS: Context quality metrics"
else
  log_warning "  WARN: Context quality could be improved"
  # Don't fail on quality metrics, just warn
fi

# Cleanup temp file
rm -f "$TEMP_CTX"

if $ALL_PASS; then
  log_success "🎉 All Context Engineering Revolution tests passed!"
  log_info "Your toolkit is ready to lead the context engineering revolution!"
  exit 0
else
  log_error "❌ Some tests failed. The revolution demands excellence!"
  exit 1
fi
