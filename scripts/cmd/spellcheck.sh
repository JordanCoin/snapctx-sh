#!/usr/bin/env bash
# scripts/cmd/spellcheck.sh - Repository spell checking
set -euo pipefail

# Source shared libraries using robust BASH_SOURCE path
# shellcheck source=../lib/colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/colors.sh"
# shellcheck source=../lib/log.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
# shellcheck source=../lib/util.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/util.sh"
# shellcheck source=../lib/security.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/security.sh"

PROJECT_ROOT=$(validate_project_root "${PROJECT_ROOT:-.}") || exit 1
JSON_OUTPUT=$(validate_boolean_flag "JSON_OUTPUT" "${JSON_OUTPUT:-false}") || exit 1

show_help() {
  log_info "Usage: $(basename "$0") [--help]"
  log_info "  --help, -h   Show this help message"
  log_info "  --json, -j   Output JSON (handled globally)"
}

while [[ ${1:-} == -* ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

run_spellcheck() {
  local issues=()

  if ! command_exists codespell; then
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      jq -n --arg path "$PROJECT_ROOT" '{status:"skipped", reason:"codespell not installed", checked_path:$path}'
    else
      log_warning "codespell not installed; skipping spellcheck."
      log_info "Install with: pip install codespell"
    fi
    return 0
  fi

  # Run codespell with safe defaults and capture results
  while IFS= read -r line; do
    issues+=("$line")
  done < <(
    cd "$PROJECT_ROOT" && \
    codespell --quiet-level 2 --skip ".git,*.png,*.jpg,*.jpeg,*.gif,node_modules,dist,.venv" || true
  )

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    if [[ ${#issues[@]} -eq 0 ]]; then
      jq -n --arg path "$PROJECT_ROOT" '{status:"clean", checked_path:$path, issues: []}'
    else
      printf '%s\n' "${issues[@]}" | jq -R -s --arg path "$PROJECT_ROOT" '
        split("\n")
        | map(select(length>0))
        | map(capture("(?<file>[^:]+):(?<line>\\d+):(?<detail>.*)"))
        | {status:"issues", checked_path:$path, issues:.}
      '
    fi
  else
    log_header "SPELLCHECK"
    if [[ ${#issues[@]} -eq 0 ]]; then
      log_success "No spelling issues found in $PROJECT_ROOT"
    else
      log_warning "Potential spelling issues detected:"
      for issue in "${issues[@]}"; do
        log_info "  $issue"
      done
    fi
  fi
}

run_spellcheck
