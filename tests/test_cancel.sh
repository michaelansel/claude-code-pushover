#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "Cancellation tests"

# --- Tests ---

test_cancel_removes_markers() {
  write_config
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  assert_marker_exists

  invoke_cancel
  assert_no_marker
}

test_cancel_preserves_rate_files() {
  write_config
  invoke_hook "$(make_input test-session Notification permission_prompt)"

  local rate_file="$TMPDIR/claude-pushover/.rate_test-session"
  assert_file_exists "$rate_file"

  invoke_cancel

  assert_file_exists "$rate_file"
}

test_cancel_empty_dir() {
  # cancel.sh should succeed even if marker dir doesn't exist yet
  mkdir -p "$TMPDIR/claude-pushover"
  invoke_cancel
  pass "cancel on empty directory succeeds"
}

# --- Run ---

run_test "cancel removes marker files" test_cancel_removes_markers
run_test "cancel preserves .rate_* files" test_cancel_preserves_rate_files
run_test "cancel succeeds on empty directory" test_cancel_empty_dir

report
