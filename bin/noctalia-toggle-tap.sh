#!/bin/bash
current=$(hyprctl -j getoption input:touchpad:tap-to-click | jq -r '.int')
if [ "$current" -eq 1 ]; then
    hyprctl keyword input:touchpad:tap-to-click false
    notify-send -e "Touchpad" "Tap-to-click disabled" -t 2000
else
    hyprctl keyword input:touchpad:tap-to-click true
    notify-send -e "Touchpad" "Tap-to-click enabled" -t 2000
fi
