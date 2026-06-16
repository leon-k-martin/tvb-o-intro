# Standalone TVB-O lecture deck
# Point SRC at the workshop repo (default assumes it sits next to this one).
SRC ?= ../tvb-ontology-optim-workshop

.DEFAULT_GOAL := help

.PHONY: help sync watch render preview dev repro all clean

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-9s\033[0m %s\n",$$1,$$2}'

sync:  ## Pull slides + materials from the workshop repo (override: make sync SRC=/path)
	SRC="$(SRC)" ./sync.sh

watch:  ## Auto-sync on every workshop-repo change (run alongside `make preview`)
	SRC="$(SRC)" ./watch.sh

render:  ## Render the deck -> index.html (uses the _freeze cache, no Python needed)
	quarto render

repro:  ## Reproduce from source: drop the cache + re-execute every cell (needs requirements.txt env)
	rm -rf _freeze/index
	quarto render

preview:  ## Live-reloading preview (this repo's files only)
	quarto preview

dev:  ## Auto-sync + live preview in ONE command (Ctrl-C stops both)
	@echo "watch + preview — edit the workshop repo and it flows through here. Ctrl-C to stop."
	@SRC="$(SRC)" ./watch.sh & \
	wpid=$$!; \
	trap 'kill $$wpid 2>/dev/null' EXIT INT TERM; \
	quarto preview

all: sync render  ## Sync from the workshop repo, then render

clean:  ## Remove render artifacts
	rm -rf .quarto index.html index_files mathjax-config.js _site
