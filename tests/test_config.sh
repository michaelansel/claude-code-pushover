#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "Config validation tests"

# --- Tests ---

test_no_config_file() {
  # No config file created — hook should exit silently
  invoke_hook "$(make_input)"
  assert_no_marker
  assert_curl_not_called
}

test_empty_user_key() {
  write_config "" "test-app-token"
  invoke_hook "$(make_input)"
  assert_no_marker
  assert_curl_not_called
}

test_empty_app_token() {
  write_config "test-user-key" ""
  invoke_hook "$(make_input)"
  assert_no_marker
  assert_curl_not_called
}

test_valid_config() {
  write_config
  invoke_hook "$(make_input)"
  assert_marker_exists
}

# --- Run ---

run_test "no config file → no marker, no curl" test_no_config_file
run_test "empty user_key → no marker" test_empty_user_key
run_test "empty app_token → no marker" test_empty_app_token
run_test "valid config → marker created" test_valid_config

report
