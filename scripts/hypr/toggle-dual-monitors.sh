#!/usr/bin/env bash

set -euo pipefail

HYPR_DIR="$HOME/.config/hypr"
DOTS_DIR="$HOME/dotfiles/.config/hypr"

LINK="$HYPR_DIR/monitors.conf"
DUAL="$DOTS_DIR/dual-monitor.conf"
SINGLE="$DOTS_DIR/single-monitor.conf"

# Resolve current symlink target (absolute, if it exists)
if [[ -L "$LINK" ]]; then
    CURRENT="$(readlink -f "$LINK")"
else
    CURRENT=""
fi

if [[ "$CURRENT" == "$DUAL" ]]; then
    ln -sf "$SINGLE" "$LINK"
    echo "Switched to single-monitor.conf"
elif [[ "$CURRENT" == "$SINGLE" ]]; then
    ln -sf "$DUAL" "$LINK"
    echo "Switched to dual-monitor.conf"
else
    ln -sf "$DUAL" "$LINK"
    echo "monitors.conf was unset or unknown — defaulting to dual-monitor.conf"
fi

