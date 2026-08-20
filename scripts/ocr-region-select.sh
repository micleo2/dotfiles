#!/bin/bash
# ocr — select a screen region, OCR it with tesseract, put the text on the clipboard.
# Deps: slurp, grim, wl-clipboard, tesseract, tesseract-data-eng.

# Comma-joined tesseract language codes, mirroring Omarchy's OMARCHY_OCR_LANGS
# (default "eng"). Add more with tesseract-data-<lang>.
LANGS="${OCR_LANGS:-eng}"

SELECTION=$(slurp 2>/dev/null) || exit 0
[[ -n $SELECTION ]] || exit 0

TEXT=$(grim -g "$SELECTION" - | tesseract stdin stdout --oem 1 --psm 6 -l "$LANGS" --dpi 300 -c preserve_interword_spaces=1 2>/dev/null)
[[ -n $TEXT ]] || {
  notify-send -u critical "OCR" "No text found in selection" -t 2000
  exit 1
}

printf "%s" "$TEXT" | wl-copy
