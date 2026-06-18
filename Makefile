.PHONY: help setup prepare train analysis leaderboard clean

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

setup:  ## Install dependencies with uv
	uv sync

prepare:  ## Download data and train the tokenizer (one-time)
	uv run prepare.py

train:  ## Run a single ~5 minute training experiment
	uv run train.py

analysis:  ## Launch the analysis notebook
	uv run jupyter notebook analysis.ipynb

leaderboard:  ## Print experiments ranked by val_bpb
	uv run scripts/leaderboard.py

clean:  ## Remove generated caches
	rm -rf __pycache__ .ipynb_checkpoints
