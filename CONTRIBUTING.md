# Contributing

Thanks for your interest in autoresearch. This is a deliberately small repo, so
the bar for changes is "does it keep the core loop simple and reviewable?"

## Ground rules

- **`prepare.py` is fixed.** It holds the constants and data/eval utilities that
  make experiments comparable. Don't change its behavior in a PR.
- **`train.py` is the agent's file.** Human-authored PRs should avoid baking in
  one specific architecture; keep the baseline neutral.
- **`program.md` is the agent's instructions.** Improvements here are welcome.

## Before you open a PR

```bash
make setup      # uv sync
make prepare    # one-time data + tokenizer
make train      # confirm a run completes
```

A run should finish a full 5-minute budget and print a `val_bpb` number without
crashing.

## Style

- Python: 4-space indent, keep functions self-contained (see `.editorconfig`).
- Commit messages: short imperative subject, optional body explaining *why*.

## Forks for other platforms

If you port autoresearch to MacOS / Windows / AMD / CPU, open an issue linking
your fork and we'll add it to the "Notable forks" section of the README.
