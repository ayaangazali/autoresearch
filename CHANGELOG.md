# Changelog

All notable changes to this fork are documented here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/).

## Unreleased

### Added
- SSH setup guide for driving a remote GPU box (`docs/setup-ssh.md`).
- Troubleshooting guide (`docs/troubleshooting.md`).
- `CONTRIBUTING.md` with ground rules and a pre-PR checklist.
- `Makefile` with `setup`, `prepare`, `train`, `analysis`, and `leaderboard`
  targets.
- `scripts/leaderboard.py` — ranks experiments by `val_bpb` with a live
  `--watch` mode.
- `.editorconfig` for consistent formatting.
- `LICENSE` file (MIT).

### Changed
- README: added a table of contents, a monitoring section, and an updated
  project-structure listing.
