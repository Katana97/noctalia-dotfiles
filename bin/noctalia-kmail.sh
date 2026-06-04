#!/bin/bash
COLORS_FILE="$HOME/.config/noctalia/colors.json"
KMAIL_RC="$HOME/.config/kmail2rc"
hex=$(jq -r ".mSurface" "$COLORS_FILE" | tr -d "#")
r=$((16#${hex:0:2}))
g=$((16#${hex:2:2}))
b=$((16#${hex:4:2}))
rgb="${r},${g},${b}"
kwriteconfig6 --file "$KMAIL_RC" --group Reader --key ColorbarBackgroundHTML "$rgb"
kwriteconfig6 --file "$KMAIL_RC" --group Reader --key ColorbarForegroundHTML "$rgb"
kwriteconfig6 --file "$KMAIL_RC" --group Reader --key ColorbarBackgroundPlain "$rgb"
kwriteconfig6 --file "$KMAIL_RC" --group Reader --key ColorbarForegroundPlain "$rgb"
kwriteconfig6 --file "$KMAIL_RC" --group Reader --key defaultColors false
echo "[noctalia-kmail] HTML status bar hidden (mSurface #${hex} → ${rgb})"
