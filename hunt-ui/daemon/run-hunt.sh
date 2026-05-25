#!/bin/zsh
# autoresearch PAPER-HUNT daemon — runs headless `claude -p` hourly to grow the
# knowledge graph + synthesize cross-paper ideas, then repaints the live dashboard.
# Lives in ~/.paperhunt (NOT ~/Documents) to avoid macOS TCC restrictions on launchd.
# SEPARATE from ~/.autoresearch (the stock screener). Do not conflate them.
set -uo pipefail

HUNT="$HOME/.paperhunt"
LOGDIR="$HUNT/logs"
RUNS="$HUNT/runs"
mkdir -p "$LOGDIR" "$RUNS"
TS="$(date +%Y-%m-%d_%H%M%S)"

# PATH for launchd's minimal env (claude lives in ~/.local/bin)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Bill to a specific Anthropic API key if provided; else use Claude Code's existing auth.
KEYFILE="$HOME/.config/paperhunt/anthropic.key"
if [ -f "$KEYFILE" ]; then
  export ANTHROPIC_API_KEY="$(tr -d ' \t\r\n' < "$KEYFILE")"
fi

cd "$HUNT" || exit 1

# Keep the dashboard reachable from the MacBook. Hardened server: binds all interfaces
# but serves ONLY index.html + hunt.json (not the rest of ~/.paperhunt).
if ! lsof -ti tcp:8732 >/dev/null 2>&1; then
  ( cd "$HUNT" && nohup python3 "$HUNT/serve.py" 8732 >"$LOGDIR/server.log" 2>&1 & )
fi

# Back up current data so a bad run is recoverable.
[ -f "$HUNT/hunt.json" ] && cp "$HUNT/hunt.json" "$RUNS/hunt-$TS.json"

echo "=== paperhunt run $TS (key:$([ -f "$KEYFILE" ] && echo file || echo cc-auth)) ===" >> "$LOGDIR/run.log"

# 1500s (25 min) wall — the old 900s killed every run mid-flight (status=124) before the
# late steps (trending, synthesis) ran, so the dashboard went stale. Still well under the
# 3600s launchd StartInterval, so runs never overlap.
# Least privilege: the agent only needs to search papers, fetch web pages, and read/write
# files — NOT run shell. Whitelisting tools (instead of --dangerously-skip-permissions)
# means a prompt-injection in an arXiv/HF abstract can't escalate to arbitrary bash.
# JSON validation is done by this wrapper below, so the agent never needs Bash.
timeout 1500 claude -p "$(cat "$HUNT/hunt-prompt.md")" \
  --model claude-sonnet-4-6 \
  --max-turns 60 \
  --allowedTools "Read Write WebFetch mcp__hf-mcp-server__paper_search mcp__arxiv__search_papers mcp__arxiv__get_abstract mcp__arxiv__download_paper mcp__arxiv__read_paper mcp__arxiv__semantic_search" \
  >> "$LOGDIR/run.log" 2>&1
STATUS=$?

# Validate output; restore the backup if the agent produced broken JSON.
if ! python3 -c "import json; json.load(open('$HUNT/hunt.json'))" 2>/dev/null; then
  echo "[$TS] INVALID hunt.json (status=$STATUS) — restoring backup" >> "$LOGDIR/run.log"
  [ -f "$RUNS/hunt-$TS.json" ] && cp "$RUNS/hunt-$TS.json" "$HUNT/hunt.json"
fi

# Keep only the 48 most recent backups.
ls -1t "$RUNS"/hunt-*.json 2>/dev/null | tail -n +49 | xargs -I{} rm -f {} 2>/dev/null

echo "=== paperhunt end $(date +%Y-%m-%d_%H%M%S) status=$STATUS ===" >> "$LOGDIR/run.log"
