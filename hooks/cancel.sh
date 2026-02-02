#!/usr/bin/env bash
set -euo pipefail

# Read and discard stdin (hook protocol requires it)
cat > /dev/null

MARKER_DIR="${TMPDIR:-/tmp}/claude-pushover"

# Remove all pending markers. The glob * does not match dotfiles like
# .rate_*, so per-session rate limit state is preserved across cancels.
rm -f "$MARKER_DIR"/* 2>/dev/null || true

exit 0
