#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "Event mapping tests"

# --- Tests ---

test_permission_prompt() {
  write_config
  invoke_hook "$(make_input test-session Notification permission_prompt)"
  assert_marker_exists
}

test_idle_prompt() {
  write_config
  invoke_hook "$(make_input test-session Notification idle_prompt)"
  assert_marker_exists
}

test_stop() {
  write_config
  invoke_hook "$(make_input test-session Stop)"
  assert_marker_exists
}

test_unknown_event() {
  write_config
  invoke_hook "$(make_input test-session UnknownEvent)"
  assert_no_marker
}

test_unknown_notif_type() {
  write_config
  invoke_hook "$(make_input test-session Notification unknown_type)"
  assert_no_marker
}

test_project_name_in_title() {
  write_config "test-user" "test-token" 1 0
  invoke_hook "$(make_input test-session Notification permission_prompt 'Test msg' /tmp/my-project)"
  # Wait for background process
  sleep 2
  assert_curl_log_contains "my-project: Permission Needed"
}

test_no_project_name() {
  write_config "test-user" "test-token" 1 0
  invoke_hook "$(make_input test-session Notification permission_prompt 'Test msg' '')"
  sleep 2
  assert_curl_log_contains "title=Permission Needed"
  assert_curl_log_not_contains ": Permission Needed"
}

# --- Run ---

run_test "Notification/permission_prompt → marker" test_permission_prompt
run_test "Notification/idle_prompt → marker" test_idle_prompt
run_test "Stop → marker" test_stop
run_test "unknown hook_event_name → no marker" test_unknown_event
run_test "unknown notification_type → no marker" test_unknown_notif_type
run_test "project name included in title" test_project_name_in_title
run_test "no project name when cwd empty" test_no_project_name

report
