# Troubleshooting

Common failure modes when running autoresearch and how to get unstuck.

## A run hangs before the timer starts

The 5-minute budget excludes startup and `torch.compile`. The first run after a
code change can take a few minutes to compile — that's expected. If it sits for
much longer:

- Confirm the GPU is visible: `nvidia-smi`.
- Check the log for a download stall during the one-time data prep
  (`uv run prepare.py`).

## `val_bpb: 0.000000` in results.tsv

That's the convention for a crashed run — the leaderboard treats it as the
worst possible score and sinks it to the bottom. Look at `run.log` for the real
exception:

```bash
grep -i "error\|traceback\|nan" run.log
```

A `NaN` loss is usually a learning rate that's too high after an architecture
change.

## Out-of-memory (OOM)

VRAM is a soft constraint. If a run OOMs, the usual knobs (see the README's
platform-support section) are `DEPTH`, `DEVICE_BATCH_SIZE`, `MAX_SEQ_LEN`, and
`TOTAL_BATCH_SIZE` in `train.py` / `prepare.py`.

## Connection drops mid-sweep

Run the agent inside `tmux` so a dropped SSH session doesn't kill it — see
[setup-ssh.md](setup-ssh.md).

## The leaderboard says "no results file"

`results.tsv` is created on the first experiment and is intentionally left
untracked by git. If you're viewing results pulled from a remote box, point the
script at the file explicitly:

```bash
uv run scripts/leaderboard.py path/to/results.tsv
```
