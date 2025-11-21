#!/usr/bin/env bash
# universal-toolkit.sh — drop-in project reconnaissance script
# Dispatches to commands in scripts/cmd/*.sh
# -----------------------------------------------------------------------------
set -euo pipefail

# --- Configuration and Environment -------------------------------------------

# Security validations for environment variables
# shellcheck source=./scripts/lib/security.sh
source "$(dirname "$0")/scripts/lib/security.sh"

PROJECT_ROOT=$(validate_project_root "${PROJECT_ROOT:-.}") || exit 1
BASE_JSON_OUTPUT=$(validate_boolean_flag "JSON_OUTPUT" "${JSON_OUTPUT:-false}") || exit 1

# --- Library Sourcing --------------------------------------------------------

# Source shared libraries relative to this script's location
# shellcheck source=./scripts/lib/colors.sh
source "$(dirname "$0")/scripts/lib/colors.sh"
# shellcheck source=./scripts/lib/log.sh
source "$(dirname "$0")/scripts/lib/log.sh"
# shellcheck source=./scripts/lib/util.sh
source "$(dirname "$0")/scripts/lib/util.sh"

# --- Argument Parsing and Dispatch -------------------------------------------

show_help() {
  log_header "Universal Toolkit"
  log_info "Usage: $(basename "$0") <command> [options]"
  log_info ""
  log_info "Available commands:"
  for cmd_script in scripts/cmd/*.sh; do
    cmd_name=$(basename "$cmd_script" .sh)
    description=$(grep -m 1 '^# scripts/cmd/' "$cmd_script" | sed 's/^# scripts\/cmd\/[^ ]* - //')
    printf "  %-20s %s\n" "$cmd_name" "${description:-}"
  done
  log_info ""
  log_info "Global options:"
  log_info "  -j, --json    Output in JSON format"
  log_info "  -h, --help    Show this help message"
}

# Handle global options and command
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  show_help
  exit 0
fi

if [[ "${1:-}" == "--version" || "${1:-}" == "version" ]]; then
  echo "snapctx-sh 0.2.0"
  exit 0
fi

COMMAND="${1:-cheatsheet}"
shift || true # Shift even if no arguments

JSON_OUTPUT="$BASE_JSON_OUTPUT"
# Filter arguments and check for --json
filtered_args=()
for arg in "$@"; do
  if [[ "$arg" == "-j" || "$arg" == "--json" ]]; then
    JSON_OUTPUT="true"
  else
    filtered_args+=("$arg")
  fi
done
export PROJECT_ROOT
export JSON_OUTPUT

# Use filtered arguments instead of original $@
if [[ ${#filtered_args[@]} -gt 0 ]]; then
  set -- "${filtered_args[@]}"
else
  set --
fi

CMD_SCRIPT="scripts/cmd/${COMMAND}.sh"

if [[ ! -f "$CMD_SCRIPT" ]]; then
  log_error "Unknown command: $COMMAND"
  show_help
  exit 1
fi

# --- Command Execution -------------------------------------------------------

# Pass all remaining arguments to the command script
# The command script will handle its own options
# shellcheck source=/dev/null
source "$CMD_SCRIPT" "$@"
