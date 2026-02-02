#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "Rate limiting tests"

# --- Tests ---

test_first_call_creates_marker() {
  write_config "u" "t" 60 5
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  assert_marker_exists
}

test_second_call_within_window() {
  write_config "u" "t" 60 5
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  # Count markers after first call
  local first_count
  first_count=$(find "$TMPDIR/claude-pushover" -maxdepth 1 -not -name '.*' -type f | wc -l | tr -d ' ')

  # Second call immediately — within rate window
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  local second_count
  second_count=$(find "$TMPDIR/claude-pushover" -maxdepth 1 -not -name '.*' -type f | wc -l | tr -d ' ')

  if [[ "$second_count" -eq "$first_count" ]]; then
    pass "no additional marker within rate window"
  else
    fail "expected $first_count markers, got $second_count"
  fi
}

test_after_rate_window() {
  # Use a long delay so bg processes don't clean up markers during the test
  write_config "u" "t" 60 1
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  assert_marker_exists

  sleep 2  # Wait for rate window (1s) to expire

  invoke_hook "$(make_input test-session Notification permission_prompt)"
  # Should now have 2 markers (both bg processes have 60s delay, won't fire)
  local count
  count=$(find "$TMPDIR/claude-pushover" -maxdepth 1 -not -name '.*' -type f | wc -l | tr -d ' ')
  if [[ "$count" -ge 2 ]]; then
    pass "new marker after rate window expires"
  else
    fail "expected 2+ markers after rate window, got $count"
  fi
}

# --- Run ---

run_test "first call creates marker" test_first_call_creates_marker
run_test "second call within rate window → no new marker" test_second_call_within_window
run_test "second call after rate window → new marker" test_after_rate_window

report
