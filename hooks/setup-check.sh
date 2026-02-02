#!/usr/bin/env bash
set -euo pipefail

# Read and discard stdin (hook protocol requires it)
cat > /dev/null

CONFIG_FILE="$HOME/.claude/plugin-config/pushover-notify.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
  jq -n '{
    "continue": true,
    "systemMessage": "Pushover plugin is not configured yet. Run /notify-pushover:setup to configure your Pushover API credentials."
  }'
  exit 0
fi

USER_KEY=$(jq -r '.user_key // empty' "$CONFIG_FILE")
APP_TOKEN=$(jq -r '.app_token // empty' "$CONFIG_FILE")

if [[ -z "$USER_KEY" || "$USER_KEY" == "your-pushover-user-key" || -z "$APP_TOKEN" || "$APP_TOKEN" == "your-pushover-app-token" ]]; then
  jq -n '{
    "continue": true,
    "systemMessage": "Pushover plugin credentials are incomplete or still set to placeholder values. Run /notify-pushover:setup to configure your API credentials."
  }'
  exit 0
fi

exit 0
