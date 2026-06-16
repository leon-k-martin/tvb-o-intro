#!/usr/bin/env bash
# Sync the slide deck + all referenced materials from the workshop repo into this
# standalone lecture repo. Repeatable and non-destructive to this repo's own files
# (_quarto.yml, _slides-home-btn.html, README.md, Makefile, sync.sh, .gitignore).
#
# Usage:
#   ./sync.sh                          # SRC defaults to ../tvb-ontology-optim-workshop
#   SRC=/path/to/workshop ./sync.sh
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SRC:-$DEST/../tvb-ontology-optim-workshop}"

if [[ ! -f "$SRC/slides.qmd" ]]; then
  echo "ERROR: workshop repo not found at: $SRC" >&2
  echo "       pass it explicitly, e.g.  SRC=/path/to/tvb-ontology-optim-workshop ./sync.sh" >&2
  exit 1
fi
SRC="$(cd "$SRC" && pwd)"
echo "Syncing  FROM  $SRC"
echo "          TO   $DEST"

# --- the slide sources that make up THIS deck (active includes only) ----------
# NOTE: the workshop's _03-setup and _06-parameter-exploration chapters are
# commented out in slides.qmd and are intentionally NOT part of this deck.
QMD=(
  slides.qmd
  authors_gallery.qmd
  slides/_01-intro.qmd
  slides/_02-fair-model.qmd
  slides/_04-clinical.qmd
  slides/_05-bifurcation.qmd
  slides/_07-stimulation.qmd
)
# --- fixed support files (this repo's _quarto.yml / header / README stay local) -
SUPPORT=(
  slides.css
  bibliography.bib
  brain-network-background.html
  brain-build.html
  brain-recap.html
)

echo "==> slide sources + support files"
mkdir -p "$DEST/slides"
for f in "${QMD[@]}" "${SUPPORT[@]}"; do
  # the deck's entry point is index.qmd here (so the build is index.html); the
  # workshop repo calls it slides.qmd.
  dest="$f"; [[ "$f" == "slides.qmd" ]] && dest="index.qmd"
  mkdir -p "$DEST/$(dirname "$dest")"
  cp "$SRC/$f" "$DEST/$dest"
done

# --- derive referenced assets (img/ data/ js/) straight from the sources -------
# so newly-added figures get picked up automatically.
echo "==> referenced assets (img/ data/ js/)"
tmp="$(mktemp)"
( cd "$SRC" && grep -rhoE '(img|data|js)/[A-Za-z0-9_./-]+\.(png|jpg|jpeg|gif|svg|mp4|webm|json|js)' \
    "${QMD[@]}" slides.css brain-network-background.html brain-build.html brain-recap.html 2>/dev/null ) \
  | sort -u > "$tmp"
echo "    $(wc -l < "$tmp" | tr -d ' ') files referenced"
missing=0
while read -r p; do [[ -e "$SRC/$p" ]] || { echo "    MISSING in source: $p"; missing=$((missing+1)); }; done < "$tmp"
[[ "$missing" -eq 0 ]] || echo "    WARNING: $missing referenced asset(s) missing in source"
rsync -a --files-from="$tmp" "$SRC/" "$DEST/"
rm -f "$tmp"

# --- tvbo-platform demo videos: sync the whole set even if a slide doesn't yet -
# reference one (the workshop's pre-render hook keeps img/videos/tvbo-*.mp4 fresh).
echo "==> tvbo-platform demo videos (img/videos/tvbo-*.mp4)"
mkdir -p "$DEST/img/videos"
rsync -a "$SRC"/img/videos/tvbo-*.mp4 "$DEST/img/videos/" 2>/dev/null || \
  echo "    (no tvbo-*.mp4 found in source)"

# --- render data the code cells read (so the deck is reproducible from source) -
echo "==> render data (_dev/ — e.g. the clinical-ontology TTL)"
rsync -a --delete "$SRC/_dev/" "$DEST/_dev/"

# --- clean-revealjs extension + freeze cache (the generated figures) -----------
echo "==> clean-revealjs extension + _freeze cache"
mkdir -p "$DEST/_extensions/grantmcdermott" "$DEST/_freeze/index"
rsync -a --delete "$SRC/_extensions/grantmcdermott/clean" "$DEST/_extensions/grantmcdermott/"
# workshop's _freeze/slides/ -> this deck's _freeze/index/ (matches index.qmd)
rsync -a --delete "$SRC/_freeze/slides/" "$DEST/_freeze/index/"
# The workshop's deck is slides.qmd, so its frozen figure paths are baked in as
# 'slides_files/...'. Here the deck is index.qmd and figures render to 'index_files/',
# so rewrite the references — otherwise every code-generated figure 404s.
hj="$DEST/_freeze/index/execute-results/html.json"
[[ -f "$hj" ]] && perl -i -pe 's/slides_files/index_files/g' "$hj"

echo "OK. Build:  make render   |   reproduce from source:  make repro"
