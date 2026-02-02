#!/usr/bin/env bash
# Test helpers: setup/teardown, assertions, invoke wrappers

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST=""

# --- Setup / Teardown ---

setup() {
  TEST_TMPDIR=$(mktemp -d)
  TEST_HOME=$(mktemp -d)
  export TMPDIR="$TEST_TMPDIR"
  export HOME="$TEST_HOME"
  export MOCK_CURL_LOG="$TEST_TMPDIR/curl.log"
  export PATH="$TESTS_DIR/bin:$PATH"

  # Create config directory
  mkdir -p "$TEST_HOME/.claude/plugin-config"
}

teardown() {
  rm -rf "$TEST_TMPDIR" "$TEST_HOME"
}

write_config() {
  local user_key="${1-test-user-key}"
  local app_token="${2-test-app-token}"
  local delay="${3-1}"
  local rate_limit="${4-0}"
  cat > "$TEST_HOME/.claude/plugin-config/pushover-notify.json" <<EOF
{
  "user_key": "$user_key",
  "app_token": "$app_token",
  "delay": $delay,
  "rate_limit": $rate_limit
}
EOF
}

# --- Invoke helpers ---

invoke_hook() {
  local json="$1"
  echo "$json" | "$PROJECT_DIR/hooks/hook.sh"
}

invoke_cancel() {
  echo '{}' | "$PROJECT_DIR/hooks/cancel.sh"
}

make_input() {
  local session_id="${1-test-session}"
  local hook_event="${2-Notification}"
  local notif_type="${3-permission_prompt}"
  local message="${4-Test message}"
  local cwd="${5-/tmp/my-project}"
  jq -n \
    --arg sid "$session_id" \
    --arg he "$hook_event" \
    --arg nt "$notif_type" \
    --arg msg "$message" \
    --arg cwd "$cwd" \
    '{session_id:$sid, hook_event_name:$he, notification_type:$nt, message:$msg, cwd:$cwd}'
}

# --- Assertions ---

assert_marker_exists() {
  local marker_dir="$TMPDIR/claude-pushover"
  local count
  count=$(find "$marker_dir" -maxdepth 1 -not -name '.*' -not -name "$(basename "$marker_dir")" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -gt 0 ]]; then
    pass "marker exists"
  else
    fail "expected marker file to exist, but none found"
  fi
}

assert_no_marker() {
  local marker_dir="$TMPDIR/claude-pushover"
  local count
  count=$(find "$marker_dir" -maxdepth 1 -not -name '.*' -not -name "$(basename "$marker_dir")" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -eq 0 ]]; then
    pass "no marker"
  else
    fail "expected no marker files, but found $count"
  fi
}

assert_curl_called() {
  if [[ -f "$MOCK_CURL_LOG" ]] && [[ -s "$MOCK_CURL_LOG" ]]; then
    pass "curl was called"
  else
    fail "expected curl to be called, but log is missing or empty"
  fi
}

assert_curl_not_called() {
  if [[ ! -f "$MOCK_CURL_LOG" ]] || [[ ! -s "$MOCK_CURL_LOG" ]]; then
    pass "curl was not called"
  else
    fail "expected curl not to be called, but log contains: $(cat "$MOCK_CURL_LOG")"
  fi
}

assert_curl_log_contains() {
  local pattern="$1"
  if grep -q "$pattern" "$MOCK_CURL_LOG" 2>/dev/null; then
    pass "curl log contains '$pattern'"
  else
    fail "expected curl log to contain '$pattern', got: $(cat "$MOCK_CURL_LOG" 2>/dev/null || echo '<empty>')"
  fi
}

assert_curl_log_not_contains() {
  local pattern="$1"
  if ! grep -q "$pattern" "$MOCK_CURL_LOG" 2>/dev/null; then
    pass "curl log does not contain '$pattern'"
  else
    fail "expected curl log NOT to contain '$pattern', got: $(cat "$MOCK_CURL_LOG")"
  fi
}

assert_file_exists() {
  if [[ -f "$1" ]]; then
    pass "file exists: $1"
  else
    fail "expected file to exist: $1"
  fi
}

assert_file_not_exists() {
  if [[ ! -f "$1" ]]; then
    pass "file does not exist: $1"
  else
    fail "expected file NOT to exist: $1"
  fi
}

# --- Test reporting ---

run_test() {
  CURRENT_TEST="$1"
  local func="$2"
  setup
  if "$func"; then
    :
  fi
  teardown
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "  \033[32m✓\033[0m %s — %s\n" "$CURRENT_TEST" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "  \033[31m✗\033[0m %s — %s\n" "$CURRENT_TEST" "$1"
}

report() {
  local total=$((PASS_COUNT + FAIL_COUNT))
  echo ""
  printf "%d tests, \033[32m%d passed\033[0m, \033[31m%d failed\033[0m\n" "$total" "$PASS_COUNT" "$FAIL_COUNT"
  return "$FAIL_COUNT"
}
