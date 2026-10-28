#!/usr/bin/env bash
# Toggle the Gruvbox "multicolour" bar by rewriting per-widget colour keys in
# Noctalia's GUI-managed settings.toml, then reloading the config.
# Usage: noctalia-multicolour.sh [on|off|toggle]   (default: toggle)
set -euo pipefail

F="${NOCTALIA_SETTINGS:-${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml}"
[ -f "$F" ] || { echo "settings file not found: $F" >&2; exit 1; }

# widget | key | value when ON | value when OFF  ("-" means the key is absent)
TABLE='battery|icon_color|primary|secondary
bluetooth|icon_color|#689d6a|secondary
network|icon_color|#458588|secondary
volume|icon_color|tertiary|secondary
notifications|icon_color|#d65d0e|secondary
launcher|icon_color|#d65d0e|tertiary
clock|color|secondary|-
session|color|error|-
workspaces|occupied_color|#458588|-'

set_key() { # widget key value
  sed -i "/^\[widget\.$1\]/,/^\[/{/^$2 = /d}" "$F"
  [ "$3" = "-" ] || sed -i "/^\[widget\.$1\]/a $2 = \"$3\"" "$F"
}

mode="${1:-toggle}"
if [ "$mode" = toggle ]; then
  cur=$(sed -n '/^\[widget\.battery\]/,/^\[/s/^icon_color = "\(.*\)"/\1/p' "$F")
  [ "$cur" = primary ] && mode=off || mode=on
fi
case "$mode" in on) col=3 ;; off) col=4 ;; *) echo "usage: $0 [on|off|toggle]" >&2; exit 2 ;; esac

[ -e "$F.pre-multicolour" ] || cp "$F" "$F.pre-multicolour"
while IFS='|' read -r w k on off; do
  [ "$col" = 3 ] && v=$on || v=$off
  set_key "$w" "$k" "$v"
done <<< "$TABLE"

command -v noctalia >/dev/null && noctalia msg config-reload >/dev/null 2>&1 || true
echo "multicolour bar: $mode"
