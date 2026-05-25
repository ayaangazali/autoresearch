#!/bin/zsh
# Deploy the paper-hunt daemon from this repo into ~/.paperhunt (non-TCC) and load the LaunchAgent.
# Idempotent: safe to re-run after editing the dashboard or prompt.
set -uo pipefail

REPO_UI="$HOME/Documents/autoresearch/hunt-ui"
SRC="$REPO_UI/daemon"
HUNT="$HOME/.paperhunt"
PLIST="$HOME/Library/LaunchAgents/com.ayaan.paperhunt.plist"

mkdir -p "$HUNT/logs" "$HUNT/runs"

# Dashboard UI always synced from the repo (source of truth for code).
cp "$REPO_UI/index.html" "$HUNT/index.html"
# hunt.json: seed only if missing (don't clobber live data the daemon is maintaining).
[ -f "$HUNT/hunt.json" ] || cp "$REPO_UI/hunt.json" "$HUNT/hunt.json"

cp "$SRC/run-hunt.sh"     "$HUNT/run-hunt.sh"
cp "$SRC/hunt-prompt.md"  "$HUNT/hunt-prompt.md"
cp "$SRC/serve.py"        "$HUNT/serve.py"
chmod +x "$HUNT/run-hunt.sh"
cp "$SRC/com.ayaan.paperhunt.plist" "$PLIST"

# (Re)load the agent.
launchctl bootout   gui/$(id -u)/com.ayaan.paperhunt 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST"

# Make sure the dashboard server is up (hardened: all interfaces, only index.html + hunt.json).
if ! lsof -ti tcp:8732 >/dev/null 2>&1; then
  ( cd "$HUNT" && nohup python3 "$HUNT/serve.py" 8732 >"$HUNT/logs/server.log" 2>&1 & )
fi

echo "deployed → $HUNT"
echo "agent:"; launchctl list | grep paperhunt || echo "  (not listed — check console login)"
IP=$(ipconfig getifaddr en1 2>/dev/null || ipconfig getifaddr en0 2>/dev/null)
echo "dashboard: http://${IP:-<lan-ip>}:8732/"
