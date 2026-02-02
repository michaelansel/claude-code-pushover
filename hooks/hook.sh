#!/usr/bin/env bash
set -euo pipefail

# Read config
CONFIG_FILE="$HOME/.claude/plugin-config/pushover-notify.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

USER_KEY=$(jq -r '.user_key // empty' "$CONFIG_FILE")
APP_TOKEN=$(jq -r '.app_token // empty' "$CONFIG_FILE")
DELAY=$(jq -r '.delay // 30' "$CONFIG_FILE")
RATE_LIMIT=$(jq -r '.rate_limit // 30' "$CONFIG_FILE")

if [[ -z "$USER_KEY" || -z "$APP_TOKEN" ]]; then
  exit 0
fi

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
RAW_MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Derive project name from working directory
PROJECT=""
if [[ -n "$CWD" ]]; then
  PROJECT=$(basename "$CWD")
fi

# Map event to title and message
TITLE=""
MESSAGE=""
case "$HOOK_EVENT" in
  Notification)
    case "$NOTIF_TYPE" in
      permission_prompt)
        TITLE="Permission Needed"
        MESSAGE="${RAW_MESSAGE:-Claude needs permission to continue}"
        ;;
      idle_prompt)
        TITLE="Waiting for Input"
        MESSAGE="${RAW_MESSAGE:-Claude is waiting for your response}"
        ;;
      *)
        exit 0 ;;  # Skip irrelevant notification types
    esac
    ;;
  Stop)
    TITLE="Task Complete"
    MESSAGE="Claude has finished working"
    ;;
  *)
    exit 0
    ;;
esac

# Prepend project name to title
if [[ -n "$PROJECT" ]]; then
  TITLE="$PROJECT: $TITLE"
fi

# Set up marker directory
MARKER_DIR="${TMPDIR:-/tmp}/claude-pushover"
mkdir -p "$MARKER_DIR"

# Per-session rate limit: check before spawning background process
RATE_FILE="$MARKER_DIR/.rate_${SESSION_ID}"
NOW=$(date +%s)
LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)
ELAPSED=$((NOW - LAST))

if [[ "$ELAPSED" -lt "$RATE_LIMIT" ]]; then
  exit 0
fi

# Write rate limit timestamp immediately (prevents process accumulation)
echo "$NOW" > "$RATE_FILE"

# Write unique marker
MARKER="$MARKER_DIR/${SESSION_ID}_${NOW}_$$"
touch "$MARKER"

# Spawn detached background process with FDs closed
(
  sleep "$DELAY"
  if [[ -f "$MARKER" ]]; then
    curl -s -o /dev/null \
      --form-string "token=$APP_TOKEN" \
      --form-string "user=$USER_KEY" \
      --form-string "title=$TITLE" \
      --form-string "message=$MESSAGE" \
      https://api.pushover.net/1/messages.json
    rm -f "$MARKER"
  fi
) </dev/null >/dev/null 2>&1 & disown

exit 0
