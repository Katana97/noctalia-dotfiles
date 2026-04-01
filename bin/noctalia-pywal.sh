#!/bin/bash
MODULE="pywal"
COLORS_FILE="$HOME/.config/noctalia/colors.json"
WAL_CACHE="$HOME/.cache/wal"

if [ ! -f "$COLORS_FILE" ]; then
    echo "[${MODULE}] ERROR: colors.json not found at $COLORS_FILE"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "[${MODULE}] ERROR: jq is not installed. Install with: sudo pacman -S jq"
    exit 1
fi

C_SURFACE=$(jq -r '.mSurface'             "$COLORS_FILE")
C_ERROR=$(jq -r '.mError'                 "$COLORS_FILE")
C_PRIMARY=$(jq -r '.mPrimary'             "$COLORS_FILE")
C_SECONDARY=$(jq -r '.mSecondary'         "$COLORS_FILE")
C_HOVER=$(jq -r '.mHover'                "$COLORS_FILE")
C_TERTIARY=$(jq -r '.mTertiary'          "$COLORS_FILE")
C_ON_SURFACE_VAR=$(jq -r '.mOnSurfaceVariant' "$COLORS_FILE")
C_ON_SURFACE=$(jq -r '.mOnSurface'       "$COLORS_FILE")
C_SURFACE_VAR=$(jq -r '.mSurfaceVariant' "$COLORS_FILE")
C_OUTLINE=$(jq -r '.mOutline'            "$COLORS_FILE")

mkdir -p "$WAL_CACHE"

cat > "$WAL_CACHE/colors.json" <<EOF
{
    "wallpaper": "None",
    "alpha": "100",
    "special": {
        "background": "${C_SURFACE}",
        "foreground": "${C_ON_SURFACE}",
        "cursor":     "${C_PRIMARY}"
    },
    "colors": {
        "color0":  "${C_SURFACE}",
        "color1":  "${C_ERROR}",
        "color2":  "${C_PRIMARY}",
        "color3":  "${C_SECONDARY}",
        "color4":  "${C_HOVER}",
        "color5":  "${C_TERTIARY}",
        "color6":  "${C_ON_SURFACE_VAR}",
        "color7":  "${C_ON_SURFACE}",
        "color8":  "${C_SURFACE_VAR}",
        "color9":  "${C_ERROR}",
        "color10": "${C_PRIMARY}",
        "color11": "${C_SECONDARY}",
        "color12": "${C_HOVER}",
        "color13": "${C_TERTIARY}",
        "color14": "${C_OUTLINE}",
        "color15": "${C_ON_SURFACE}"
    }
}
EOF

echo "[${MODULE}] ~/.cache/wal/colors.json written from Noctalia palette."
