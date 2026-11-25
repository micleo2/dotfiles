#!/bin/bash
# screenshot — capture the screen as rendered and put it on the clipboard,
# saving it to ~/Pictures as well unless --clipboard-only is given.
#   screenshot.sh <screen|region|window> [--clipboard-only]
# screen = focused monitor, region = slurp selection, window = the focused
# Hyprland window's rectangle.
# Deps: grim, slurp, jq, wl-clipboard, libnotify.

DIR="${SCREENSHOT_DIR:-$HOME/Pictures}"
MODE="$1"
CLIPBOARD_ONLY=0
[[ $2 == --clipboard-only ]] && CLIPBOARD_ONLY=1

fail() {
  notify-send -u critical "Screenshot" "$1" -t 2000
  exit 1
}

case "$MODE" in
screen)
  OUTPUT=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
  [[ -n $OUTPUT ]] || fail "No focused monitor"
  TARGET=(-o "$OUTPUT")
  ;;
region)
  SELECTION=$(slurp 2>/dev/null) || exit 0
  [[ -n $SELECTION ]] || exit 0
  TARGET=(-g "$SELECTION")
  ;;
window)
  GEOMETRY=$(hyprctl activewindow -j | jq -r 'select(.mapped) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
  [[ -n $GEOMETRY ]] || fail "No focused window"
  TARGET=(-g "$GEOMETRY")
  ;;
*)
  echo "usage: ${0##*/} <screen|region|window> [--clipboard-only]" >&2
  exit 2
  ;;
esac

if ((CLIPBOARD_ONLY)); then
  # Capture fully before wl-copy runs, so a failed grim leaves the clipboard alone.
  FILE=$(mktemp --suffix=.png) || fail "Capture failed"
  trap 'rm -f "$FILE"' EXIT
  grim "${TARGET[@]}" "$FILE" || fail "Capture failed"
  wl-copy --type image/png <"$FILE"
  notify-send "Screenshot" "Copied $MODE to clipboard" -t 2000
else
  FILE="$DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
  mkdir -p "$DIR"
  grim "${TARGET[@]}" "$FILE" || fail "Capture failed"
  wl-copy --type image/png <"$FILE"
  notify-send "Screenshot" "Saved $MODE to $FILE" -t 2000
fi
