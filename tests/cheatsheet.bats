#!/usr/bin/env bats

@test "cheatsheet --json returns valid json" {
  local workspace="${GITHUB_WORKSPACE:-$(pwd)}"
  run "$workspace/universal-toolkit.sh" -j cheatsheet
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}