#!/usr/bin/env bats

@test "spellcheck --json returns valid json" {
  local workspace="${GITHUB_WORKSPACE:-$(pwd)}"
  run "$workspace/universal-toolkit.sh" -j spellcheck
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}
