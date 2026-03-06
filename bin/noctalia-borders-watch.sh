#!/bin/bash
# =============================================================================
# noctalia-borders-watch.sh — Noctalia colours.json watcher
# Monitors colors.json for changes and triggers noctalia-apply.sh
# =============================================================================

COLORS_FILE="$HOME/.config/noctalia/colors.json"
APPLY_SCRIPT="$HOME/.local/bin/noctalia-apply.sh"

if ! command -v inotifywait &>/dev/null; then
    echo "ERROR: inotifywait not found. Install with: sudo pacman -S inotify-tools"
    exit 1
fi

if [ ! -f "$APPLY_SCRIPT" ]; then
    echo "ERROR: noctalia-apply.sh not found at $APPLY_SCRIPT"
    exit 1
fi

echo "Watching $COLORS_FILE for changes..."

while inotifywait -e close_write,moved_to,create \
    "$(dirname "$COLORS_FILE")" &>/dev/null; do
    if [ -f "$COLORS_FILE" ]; then
        echo "colours.json changed — applying theme..."
        bash "$APPLY_SCRIPT"
    fi
done
