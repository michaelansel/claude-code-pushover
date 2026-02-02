# Pushover Notifications for Claude Code

Sends [Pushover](https://pushover.net/) notifications when Claude Code is waiting for approval or has finished working — but only if you don't respond within 30 seconds.

## How It Works

- **Notification** and **Stop** hooks start a 30-second timer
- If you interact with Claude Code before the timer fires, the notification is cancelled
- Per-session rate limiting prevents notification spam

## Installation

1. Clone this repo (or install via Claude Code plugin marketplace):
   ```bash
   git clone https://github.com/michaelansel/claude-code-pushover.git ~/Code/claude-code-pushover
   ```

2. Create your config file:
   ```bash
   mkdir -p ~/.claude/plugin-config
   cp ~/Code/claude-code-pushover/config.example.json ~/.claude/plugin-config/pushover-notify.json
   ```

3. Edit `~/.claude/plugin-config/pushover-notify.json` with your Pushover credentials:
   - `user_key`: Your Pushover user key (from https://pushover.net/)
   - `app_token`: Your Pushover application token

4. Enable the plugin in Claude Code settings or marketplace.

5. Restart Claude Code.

## Configuration

| Key | Required | Default | Description |
|-----|----------|---------|-------------|
| `user_key` | Yes | — | Pushover user key |
| `app_token` | Yes | — | Pushover app token |
| `delay` | No | 30 | Seconds to wait before sending notification |
| `rate_limit` | No | 30 | Minimum seconds between notifications per session |

## Requirements

- `jq` (for JSON parsing)
- `curl` (for Pushover API calls)
- A [Pushover](https://pushover.net/) account and application

## Testing

```bash
# Test the hook directly
echo '{"session_id":"test","hook_event_name":"Notification","notification_type":"permission_prompt","message":"test"}' | ./hooks/hook.sh

# Check for marker file
ls ${TMPDIR:-/tmp}/claude-pushover/

# Wait 30s, then check for Pushover notification

# Test cancellation
echo '{}' | ./hooks/cancel.sh
```
