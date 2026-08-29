#!/bin/sh

# Background text-effects panel (autostarted from hyprland.lua).
#
# ttfx lives in another checkout, not in this repo, and its launcher reads
# `flatland.txt` and `./target/release/ttfx` by relative path -- so cd there
# first, and exit quietly when that checkout is missing (fresh machine).
TTFX_DIR="$HOME/oss/omarchy/plans/ttfx"

[ -x "$TTFX_DIR/launch.sh" ] || exit 0
cd "$TTFX_DIR" || exit 0
exec ./launch.sh
