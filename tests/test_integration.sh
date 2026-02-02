#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "Integration tests"

# --- Tests ---

test_send_after_delay() {
  write_config "my-user" "my-token" 1 0
  invoke_hook "$(make_input test-session Notification permission_prompt 'Need permission' /tmp/my-project)"
  # Wait for background process to fire
  sleep 2
  assert_curl_called
  # Marker should be cleaned up by the background process
  assert_no_marker
}

test_cancel_before_delay() {
  write_config "my-user" "my-token" 2 0
  invoke_hook "$(make_input test-session Notification permission_prompt 'Need permission' /tmp/my-project)"
  # Cancel immediately
  invoke_cancel
  # Wait for the delay to pass
  sleep 3
  assert_curl_not_called
}

test_curl_arguments() {
  write_config "my-user" "my-token" 1 0
  invoke_hook "$(make_input test-session Notification permission_prompt 'Need permission' /tmp/my-project)"
  sleep 2
  assert_curl_log_contains "token=my-token"
  assert_curl_log_contains "user=my-user"
  assert_curl_log_contains "my-project: Permission Needed"
  assert_curl_log_contains "Need permission"
}

# --- Run ---

run_test "send flow: notification sent after delay" test_send_after_delay
run_test "cancel flow: no notification if cancelled" test_cancel_before_delay
run_test "curl receives correct arguments" test_curl_arguments

report
