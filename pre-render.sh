#!/usr/bin/env bash
# Quarto pre-render hook (wired via `project.pre-render` in _quarto.yml).
#
# Refreshes this deck from the workshop repo (the ground truth) on every
# `quarto render` / `quarto preview` / `quarto publish` — but ONLY if that repo
# is actually present. A standalone build (clean clone or CI without the workshop)
# skips the sync and renders from the committed _freeze cache, so render never
# fails just because the source repo isn't checked out next to it.
#
# SRC defaults to ../tvb-ontology-optim-workshop (override: SRC=/path quarto render)
set -u

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SRC:-$DEST/../tvb-ontology-optim-workshop}"

if [[ -f "$SRC/slides.qmd" ]]; then
  echo "[pre-render] workshop found at $SRC — syncing from ground truth"
  SRC="$SRC" "$DEST/sync.sh"
else
  echo "[pre-render] no workshop repo at $SRC — skipping sync, building from committed cache"
fi
