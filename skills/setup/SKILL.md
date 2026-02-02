---
name: setup
description: Configure Pushover API credentials for push notifications
---

Walk the user through configuring the Pushover notification plugin. Follow these steps:

1. Check if `~/.claude/plugin-config/pushover-notify.json` already exists and show current status (configured or not).

2. Ask the user for their Pushover credentials:
   - **User Key**: Found at https://pushover.net/ (top of the dashboard after logging in)
   - **App Token**: Create an application at https://pushover.net/apps/build, then copy the API Token/Key

3. Ask about optional settings:
   - **delay** (default: 30) — seconds to wait before sending a notification
   - **rate_limit** (default: 30) — minimum seconds between notifications per session

4. Create the directory and write the config file:
   ```bash
   mkdir -p ~/.claude/plugin-config
   ```
   Write `~/.claude/plugin-config/pushover-notify.json` with the provided values.

5. Verify the file was written correctly by reading it back.

6. Offer to send a test notification to confirm credentials work:
   ```bash
   curl -s --form-string "token=APP_TOKEN" --form-string "user=USER_KEY" --form-string "title=Test" --form-string "message=Pushover notifications are working!" https://api.pushover.net/1/messages.json
   ```
   Check that the response contains `"status":1`.
