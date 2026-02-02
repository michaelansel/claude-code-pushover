# Claude Code Pushover Notification Plugin

## Project Overview

A Pushover notification plugin for Claude Code that sends push notifications when Claude needs attention or completes tasks. Uses a 30-second delay + cancellation pattern to avoid notification spam — if the user responds before the timer fires, the notification is cancelled.

## Architecture

Pure shell scripts, no build system. Three hook scripts wired to Claude Code's event system:

- **`hooks/hook.sh`** — Main notification trigger. Handles `Notification` (permission_prompt, idle_prompt) and `Stop` events. Creates a marker file, spawns a detached background process that sleeps for `delay` seconds, then sends a Pushover API call if the marker still exists.
- **`hooks/cancel.sh`** — Cancellation handler for `UserPromptSubmit`. Removes all pending marker files to cancel queued notifications.
- **`hooks/hooks.json`** — Event-to-script mapping configuration.
- **`hooks/setup-check.sh`** — Setup hook that checks for missing credentials and prompts the user to run `/notify-pushover:setup`.
- **`skills/setup/SKILL.md`** — Interactive setup skill that walks users through configuring Pushover credentials.

## Key Files

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata for Claude Code |
| `hooks/hooks.json` | Hook event configuration (4 events) |
| `hooks/hook.sh` | Notification trigger + rate limiting |
| `hooks/cancel.sh` | Notification cancellation |
| `hooks/setup-check.sh` | Setup hook — validates config on plugin load |
| `skills/setup/SKILL.md` | Interactive credential setup skill |
| `config.example.json` | User configuration template |

## State Management

All state is filesystem-based in `${TMPDIR:-/tmp}/claude-pushover/`:
- Marker files (`${SESSION_ID}_${TIMESTAMP}_$$`) track pending notifications
- Rate-limit files (`.rate_${SESSION_ID}`) track last notification time per session

User config lives at `~/.claude/plugin-config/pushover-notify.json`.

## Dependencies

Runtime only: `bash`, `jq`, `curl`, `date`. No package manager or build step.

## Versioning

This plugin uses semver in `.claude-plugin/plugin.json`. Bump the version on every user-facing change:
- **Patch** (1.2.x): Bug fixes, minor tweaks
- **Minor** (1.x.0): New features, behavior changes
- **Major** (x.0.0): Breaking changes

The marketplace repo (`claude-code-plugins`) does NOT track versions — it pulls from this repo at head.

## Testing

Manual testing via stdin JSON piping as documented in README.md:
```bash
echo '{"session_id":"test","hook_event_name":"Notification","notification_type":"permission_prompt","message":"Test","cwd":"/tmp/my-project"}' | ./hooks/hook.sh
ls ${TMPDIR:-/tmp}/claude-pushover/
echo '{}' | ./hooks/cancel.sh
```
