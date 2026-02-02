#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Code Pushover Test Suite ==="
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0
SUITE_FAILURES=()

for test_file in "$TESTS_DIR"/test_*.sh; do
  name=$(basename "$test_file")
  echo "--- $name ---"
  output=$("$test_file" 2>&1) || true
  echo "$output"

  # Parse pass/fail counts from the report line
  pass=$(echo "$output" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)
  fail=$(echo "$output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))

  if [[ "$fail" -gt 0 ]]; then
    SUITE_FAILURES+=("$name")
  fi
  echo ""
done

echo "==========================================="
printf "TOTAL: %d tests, \033[32m%d passed\033[0m, \033[31m%d failed\033[0m\n" \
  $((TOTAL_PASS + TOTAL_FAIL)) "$TOTAL_PASS" "$TOTAL_FAIL"

if [[ ${#SUITE_FAILURES[@]} -gt 0 ]]; then
  echo ""
  echo "Failed suites:"
  for s in "${SUITE_FAILURES[@]}"; do
    echo "  - $s"
  done
  exit 1
fi

exit 0
