# paper-hunt daemon — 24/7 local, hourly

Runs the paper-hunt pipeline **every hour, locally on the Mac Mini, with no session open**.
Each run: searches new frontier papers → dedups by arXiv id against the knowledge graph →
adds nodes + connection edges → writes a ~300-word take → re-ranks → synthesizes one new
cross-paper idea → repaints the live dashboard (`:8732`).

## ⚠️ Two important facts

1. **Live runtime lives in `~/.paperhunt/`, NOT here in `~/Documents`.**
   macOS TCC blocks background `launchd` agents from reading/writing `~/Documents`. So the
   running copy of the dashboard + data + scripts lives in the non-protected `~/.paperhunt/`.
   This repo `daemon/` folder is the **version-controlled source**; `install.sh` deploys it.
2. **Not the stock screener.** `~/.autoresearch` + LaunchAgent `com.user.autoresearch` is a
   *separate* stock screener. This paper-hunt uses `~/.paperhunt` + `com.ayaan.paperhunt`.
   Never touch the other one.

## Files
- `run-hunt.sh` — entrypoint: backs up data, ensures the `:8732` server is up, runs headless
  `claude -p` with `hunt-prompt.md`, validates the JSON, restores backup on failure.
- `hunt-prompt.md` — the agent instructions (bounded: ≤3 searches, ≤2 new papers, 1 new idea/run).
- `com.ayaan.paperhunt.plist` — LaunchAgent: `StartInterval 3600` (hourly) + `RunAtLoad`.
- `install.sh` — deploys all of the above to `~/.paperhunt` and loads the agent.

## Install / update
```bash
~/Documents/autoresearch/hunt-ui/daemon/install.sh
```

## Billing / auth
Uses Claude Code's existing auth by default (works headless here). To bill a **specific
Anthropic API key**, drop it in a file (never commit it):
```bash
mkdir -p ~/.config/paperhunt && printf '%s' 'sk-ant-...' > ~/.config/paperhunt/anthropic.key && chmod 600 ~/.config/paperhunt/anthropic.key
```
`run-hunt.sh` sources it automatically on the next run.

## Operate
```bash
# is it loaded?           (col 2 = last exit code, 0 = clean)
launchctl list | grep paperhunt
# force a run now
launchctl kickstart -k gui/$(id -u)/com.ayaan.paperhunt
# watch the latest run
tail -f ~/.paperhunt/logs/run.log
# stop it for good
launchctl bootout gui/$(id -u)/com.ayaan.paperhunt
```

## Requirement for "runs even when only SSH'd in"
The Mac Mini must be **console-logged-in** (enable automatic login). GUI LaunchAgents need the
user's Aqua session loaded; an SSH-only session with no console login won't start them.
