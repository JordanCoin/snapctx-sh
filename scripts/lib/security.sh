#!/usr/bin/env bash
# security.sh - Shared security and validation helpers

# Validate that a project root stays within the current working directory
validate_project_root() {
  local input_root="${1:-.}"

  if [[ -z "$input_root" ]]; then
    echo "❌ Security: PROJECT_ROOT cannot be empty" >&2
    return 1
  fi

  if [[ "$input_root" == *".."* ]]; then
    echo "❌ Security: PROJECT_ROOT cannot traverse upwards: $input_root" >&2
    return 1
  fi

  # Normalize and verify the path exists
  local normalized_root
  if ! normalized_root=$(cd "$input_root" 2>/dev/null && pwd); then
    echo "❌ Security: PROJECT_ROOT does not exist or is unreadable: $input_root" >&2
    return 1
  fi

  local workspace_root
  workspace_root=$(pwd)
  case "$normalized_root/" in
    "$workspace_root"/*) ;;
    *)
      echo "❌ Security: PROJECT_ROOT must stay within the current workspace" >&2
      return 1
      ;;
  esac

  echo "$normalized_root"
}
export -f validate_project_root

# Validate boolean-like environment flags
validate_boolean_flag() {
  local name="$1"
  local value="${2:-false}"

  if [[ "$value" != "true" && "$value" != "false" ]]; then
    echo "❌ Security: $name must be 'true' or 'false'" >&2
    return 1
  fi

  echo "$value"
}
export -f validate_boolean_flag
