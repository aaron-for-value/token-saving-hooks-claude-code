#!/bin/bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$ROOT" ]; then exit 0; fi

INPUT=$(cat)

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

TEST_OUTPUT="$ROOT/.claude/last_test_output.txt"
if [ -f "$TEST_OUTPUT" ]; then
  # Ignore stale test output older than 5 minutes — likely from a previous session
  if [ "$(uname)" = "Darwin" ]; then
    FILE_AGE=$(( $(date +%s) - $(stat -f %m "$TEST_OUTPUT") ))
  else
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$TEST_OUTPUT") ))
  fi
  if [ "$FILE_AGE" -gt 300 ]; then
    exit 0
  fi

  # Check for actual Vitest failure summary lines, not random substrings
  # Vitest reports failures as "X failed" in the summary line
  if grep -qE "Tests .* failed" "$TEST_OUTPUT" 2>/dev/null; then
    echo "Tests still fail. Before stopping, create a handoff package and invoke the planner subagent for a revised plan, then continue." >&2
    exit 2
  fi
  if grep -qE "Test Files .* failed" "$TEST_OUTPUT" 2>/dev/null; then
    echo "Tests still fail. Before stopping, create a handoff package and invoke the planner subagent for a revised plan, then continue." >&2
    exit 2
  fi
fi

exit 0
