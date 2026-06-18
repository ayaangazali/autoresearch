#!/usr/bin/env python3
"""Render results.tsv as a ranked leaderboard in the terminal.

The autonomous loop appends one row per experiment to ``results.tsv`` with the
columns ``commit  val_bpb  memory_gb  status  description``. This script reads
that file and prints the runs sorted by ``val_bpb`` (lower is better) so you can
see at a glance which experiment is currently winning.

Usage:
    uv run scripts/leaderboard.py [path/to/results.tsv] [--top N]
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

# ANSI colors; degrade gracefully when stdout is not a TTY.
_TTY = sys.stdout.isatty()
GREEN = "\033[32m" if _TTY else ""
DIM = "\033[2m" if _TTY else ""
BOLD = "\033[1m" if _TTY else ""
RESET = "\033[0m" if _TTY else ""


def load_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def parse_bpb(row: dict[str, str]) -> float:
    """A crashed run records 0.000000; treat it as 'worst' for sorting."""
    try:
        value = float(row.get("val_bpb", "") or 0.0)
    except ValueError:
        return float("inf")
    return value if value > 0 else float("inf")


def render(rows: list[dict[str, str]], top: int) -> None:
    ranked = sorted(rows, key=parse_bpb)[:top]
    best = parse_bpb(ranked[0]) if ranked else None

    print(f"{BOLD}{'#':>3}  {'val_bpb':>9}  {'mem_gb':>6}  {'commit':<10}  description{RESET}")
    print(DIM + "-" * 72 + RESET)
    for i, row in enumerate(ranked, 1):
        bpb = parse_bpb(row)
        bpb_str = f"{bpb:.6f}" if bpb != float("inf") else "  crash "
        mark = GREEN if bpb == best else ""
        print(
            f"{mark}{i:>3}  {bpb_str:>9}  {row.get('memory_gb', '?'):>6}  "
            f"{row.get('commit', '')[:10]:<10}  {row.get('description', '')}{RESET}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default="results.tsv", type=Path)
    parser.add_argument("--top", type=int, default=20, help="rows to display")
    args = parser.parse_args()

    if not args.path.exists():
        print(f"no results file at {args.path} — run an experiment first", file=sys.stderr)
        return 1

    rows = [r for r in load_rows(args.path) if r.get("commit")]
    if not rows:
        print("results.tsv has no experiments yet", file=sys.stderr)
        return 1

    render(rows, args.top)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
