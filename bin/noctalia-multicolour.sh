#!/usr/bin/env bash
# noctalia-multicolour.sh - toggle a colourful bar that adapts to the active scheme.
#   Gruvbox Muted : official Gruvbox colours (orange, blue, aqua as fixed hex)
#   any other     : palette roles only, plus an orange made from that scheme's own red
# Rewrites per-widget colour keys in Noctalia's settings.toml, then reloads config.
#
# Usage: noctalia-multicolour.sh [toggle|on|off|refresh]   (default: toggle)
#   refresh = re-apply if currently on (run from noctalia-apply.sh after a scheme change)
set -euo pipefail

F="${NOCTALIA_SETTINGS:-${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml}"
COLORS="${NOCTALIA_COLORS:-$HOME/.config/noctalia/colors.json}"
MATCH='gruvbox muted'   # palette-name substring (case-insensitive) that gets the exact Gruvbox set
[ -f "$F" ] || { echo "settings file not found: $F" >&2; exit 1; }

get() { # key from the [theme] section
  awk -v k="$1" '/^\[theme\]/{t=1;next} /^\[/{t=0} t && $1==k {sub(/^[^=]*= *"/,""); sub(/".*/,""); print; exit}' "$F"
}
scheme() {
  case "$(get source)" in
    community) get community_palette ;; builtin) get builtin ;; custom) get custom_palette ;;
  esac
}
role() { grep -o "\"$1\": *\"#[0-9a-fA-F]\{6\}\"" "$COLORS" 2>/dev/null | grep -o '#[0-9a-fA-F]\{6\}' | head -1 || true; }

orange() { # the scheme's error colour, same saturation and lightness, hue turned to orange
  local h="${1#\#}"
  awk -v r=$((16#${h:0:2})) -v g=$((16#${h:2:2})) -v b=$((16#${h:4:2})) 'function abs(v){return v<0?-v:v}
    BEGIN{ r/=255; g/=255; b/=255
      mx=(r>g?(r>b?r:b):(g>b?g:b)); mn=(r<g?(r<b?r:b):(g<b?g:b))
      l=(mx+mn)/2; d=mx-mn; k=1-abs(2*l-1); s=(d==0||k==0)?0:d/k
      c=k*s; hh=25/60; x=c*(1-abs(hh-1)); m=l-c/2
      printf "#%02x%02x%02x\n", int((c+m)*255+0.5), int((x+m)*255+0.5), int(m*255+0.5) }'
}

table() { # widget | key | value when ON | value when OFF   ("-" = key absent)
  local name err orng; name="$(scheme)"
  echo 'battery|icon_color|primary|secondary
volume|icon_color|tertiary|secondary
clock|color|secondary|-
session|color|error|-
workspaces|occupied_color|primary|-
workspaces|focused_color|secondary|-
workspaces|empty_color|-|-
control-center|icon_color|tertiary|tertiary'
  if [[ "${name,,}" == *"$MATCH"* ]]; then
    echo 'bluetooth|icon_color|#689d6a|secondary
network|icon_color|#458588|secondary
notifications|icon_color|#d65d0e|secondary
launcher|icon_color|#d65d0e|tertiary'
  else
    err="$(role mError)"; orng="error"; [ -n "$err" ] && orng="$(orange "$err")"
    echo "bluetooth|icon_color|primary|secondary
network|icon_color|secondary|secondary
notifications|icon_color|$orng|secondary
launcher|icon_color|$orng|tertiary"
  fi
}

is_on() { [ "$(sed -n '/^\[widget\.battery\]/,/^\[/s/^icon_color = "\(.*\)"/\1/p' "$F")" = primary ]; }

set_key() { # file widget key value
  sed -i "/^\[widget\.$2\]/,/^\[/{/^$3 = /d}" "$1"
  [ "$4" = "-" ] || sed -i "/^\[widget\.$2\]/a $3 = \"$4\"" "$1"
}

apply() { # on|off - only touches settings.toml if something would change
  local col w k on off v W; [ "$1" = on ] && col=3 || col=4
  W="$(mktemp)"; cp "$F" "$W"
  while IFS='|' read -r w k on off; do
    [ "$col" = 3 ] && v=$on || v=$off
    set_key "$W" "$w" "$k" "$v"
  done <<< "$(table)"
  if cmp -s "$W" "$F"; then rm -f "$W"; echo "multicolour: no change needed ($1, scheme '$(scheme)')"; return 0; fi
  [ -e "$F.pre-multicolour" ] || cp "$F" "$F.pre-multicolour"
  cat "$W" > "$F"; rm -f "$W"
  command -v noctalia >/dev/null && noctalia msg config-reload >/dev/null 2>&1 || true
  echo "multicolour bar: $1 (scheme '$(scheme)')"
}

mode="${1:-toggle}"
case "$mode" in
  toggle)  if is_on; then apply off; else apply on; fi ;;
  on|off)  apply "$mode" ;;
  refresh) if is_on; then apply on; fi ;;
  *) echo "usage: $0 [toggle|on|off|refresh]" >&2; exit 2 ;;
esac
