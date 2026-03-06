#!/bin/bash
# =============================================================================
# noctalia-icons.sh — Tela icon recolouring module
# Recolours Tela icons to match mTertiary. Caches by colour hex.
# Expects: TERTIARY exported by noctalia-apply.sh
# =============================================================================

MODULE="icons"

ICONS_BASE="$HOME/.local/share/icons/Tela-Noctalia"
ICONS_SOURCE="$HOME/.local/share/icons/Tela-Noctalia-Source"
ACTIVE_LINK="$HOME/.local/share/icons/Tela-Noctalia-Active"

# --- Dependency checks -------------------------------------------------------
if [ ! -d "$ICONS_SOURCE" ]; then
    echo "[${MODULE}] skipped — Tela-Noctalia-Source not found at $ICONS_SOURCE"
    exit 0
fi

# --- Cache check -------------------------------------------------------------
CACHE_DIR="${ICONS_BASE}-${TERTIARY}"

if [ -d "$CACHE_DIR" ]; then
    echo "[${MODULE}] Using cached icons for #${TERTIARY}"
    ln -sfn "$CACHE_DIR" "$ACTIVE_LINK"
    gtk-update-icon-cache -f "$ACTIVE_LINK" 2>/dev/null
    kbuildsycoca6 --noincremental 2>/dev/null
    exit 0
fi

# --- Cache miss — recolour from source ---------------------------------------
echo "[${MODULE}] Recolouring icons for #${TERTIARY}..."

cp -r "$ICONS_SOURCE" "$CACHE_DIR"
find "$CACHE_DIR" -name "*.svg" | while read -r svg; do
sed -i \
        -e "/ColorScheme-Highlight/s/fill=\"currentColor\"/fill=\"#${TERTIARY}\"/gI" \
        -e "/ColorScheme-Background/s/fill=\"currentColor\"/fill=\"#ffffff\"/gI" \
        -e "s/color:#5294e2/color:#${TERTIARY}/gI" \
        -e "s/#5677fc/#${TERTIARY}/gI" \
        -e "s/#5294e2/#${TERTIARY}/gI" \
        "$svg"
done

ln -sfn "$CACHE_DIR" "$ACTIVE_LINK"
gtk-update-icon-cache -f "$ACTIVE_LINK" 2>/dev/null
kbuildsycoca6 --noincremental 2>/dev/null
echo "[${MODULE}] Icons updated and cached."
