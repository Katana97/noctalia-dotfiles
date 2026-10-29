#!/usr/bin/env bash
# noctalia-multicolour.sh - swap the bar between two saved sets of widget colours:
# "on" (your colourful icons) and "off" (the plain look).
# It never decides colours itself. Each toggle first saves the colours you have right
# now (including anything you changed in Settings), then loads the other saved set.
# Only these keys in [widget.*] sections are touched; everything else is left alone.
#
# Usage: noctalia-multicolour.sh [toggle|on|off|status]   (default: toggle)
set -euo pipefail

F="${NOCTALIA_SETTINGS:-${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml}"
D="$(dirname "$F")"
MODE_FILE="$D/multicolour.mode"          # records which set is loaded: on or off
KEYS='icon_color|color|focused_color|occupied_color|empty_color'
[ -f "$F" ] || { echo "settings file not found: $F" >&2; exit 1; }

snapshot() { # print "widget|key|value" for each colour key in the [widget.*] sections of $1
  awk -v keys="^($KEYS)$" '
    /^\[/ { w=""; if (match($0,/^\[widget\.[^].]+\]/)) w=substr($0,9,RLENGTH-9); next }
    w!="" && match($0,/^[a-z_]+ = "/) { k=$1; if (k ~ keys) { v=$0; sub(/^[^=]*= *"/,"",v); sub(/".*/,"",v); print w "|" k "|" v } }
  ' "$1"
}

strip() { # print $1 without the colour keys in its [widget.*] sections
  awk -v keys="^($KEYS)$" '
    /^\[/ { w=0; if ($0 ~ /^\[widget\.[^].]+\]/) w=1; print; next }
    w && match($0,/^[a-z_]+ = /) { k=$1; if (k ~ keys) next }
    { print }
  ' "$1"
}

load() { # replace the colour keys in settings.toml with those saved in snapshot file $1
  local W w k v; W="$(mktemp)"; strip "$F" > "$W"
  while IFS='|' read -r w k v; do
    [ -n "$w" ] || continue
    grep -q "^\[widget\.$w\]" "$W" || continue
    sed -i "/^\[widget\.$w\]/a $k = \"$v\"" "$W"
  done < "$1"
  cat "$W" > "$F"; rm -f "$W"
}

mode="$(cat "$MODE_FILE" 2>/dev/null || echo on)"
want="${1:-toggle}"
case "$want" in
  status) echo "multicolour bar: $mode"; exit 0 ;;
  toggle) if [ "$mode" = on ]; then want=off; else want=on; fi ;;
  on|off) ;;
  *) echo "usage: $0 [toggle|on|off|status]" >&2; exit 2 ;;
esac
[ "$want" = "$mode" ] && { echo "multicolour bar: already $mode"; exit 0; }

cp "$F" "$F.before-toggle"                       # one-step undo: copy this back over settings.toml
snapshot "$F" > "$D/multicolour.$mode.snap"      # remember the colours as they are right now

other="$D/multicolour.$want.snap"
if [ ! -f "$other" ]; then                       # first time: seed the other set
  if [ "$want" = off ] && [ -f "$F.pre-multicolour" ]; then
    snapshot "$F.pre-multicolour" > "$other"     # plain = your bar before any of this
  elif [ "$want" = off ]; then
    : > "$other"                                 # no backup: plain = widget defaults
  else
    echo "no saved colourful set to load" >&2; exit 1
  fi
fi
load "$other"
echo "$want" > "$MODE_FILE"
command -v noctalia >/dev/null && noctalia msg config-reload >/dev/null 2>&1 || true
echo "multicolour bar: $want"
