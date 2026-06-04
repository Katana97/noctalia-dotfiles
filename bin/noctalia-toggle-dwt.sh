#!/usr/bin/env bash
DEVICE="dell097d:00-04f3:311c-touchpad"
STATE_FILE="/tmp/noctalia-dwt-state"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "off" ]; then
    hyprctl keyword "device[$DEVICE]:disable_while_typing" true
    echo "on" > "$STATE_FILE"
    notify-send "Touchpad" "Disable-while-typing: ON" -t 2000 --hint=int:transient:1
else
    hyprctl keyword "device[$DEVICE]:disable_while_typing" false
    echo "off" > "$STATE_FILE"
    notify-send "Touchpad" "Disable-while-typing: OFF (gaming mode)" -t 2000 --hint=int:transient:1
fi
