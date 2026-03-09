#!/bin/bash
# =============================================================================
# noctalia-borders.sh — Borders module
# Sets Hyprland active/inactive border colours and KDE highlight colour.
# Expects: PRIMARY, TERTIARY, SURFACE, ON_SURFACE exported by noctalia-apply.sh
# =============================================================================

MODULE="borders"

# --- Dependency checks -------------------------------------------------------
if ! command -v hyprctl &>/dev/null; then
    echo "[${MODULE}] skipped — hyprctl not found. Is Hyprland running?"
    exit 0
fi

if ! command -v kwriteconfig6 &>/dev/null; then
    echo "[${MODULE}] warning — kwriteconfig6 not found, KDE colour sync will be skipped"
    SKIP_KDE=true
fi

# --- Apply borders -----------------------------------------------------------
hyprctl keyword general:col.active_border \
    "rgba(${PRIMARY}ee) rgba(${TERTIARY}ee) 45deg"
hyprctl keyword general:col.inactive_border \
    "rgba(${SURFACE}55)"

echo "[${MODULE}] Borders updated."

# --- KDE highlight colour ----------------------------------------------------
if [ -z "$SKIP_KDE" ]; then
    kwriteconfig6 --file kdeglobals \
        --group "Colors:Button" --key ForegroundActive "#${TERTIARY}"
    kwriteconfig6 --file kdeglobals \
        --group "Colors:Selection" --key BackgroundNormal "#${TERTIARY}"
    kwriteconfig6 --file kdeglobals \
        --group "Colors:Selection" --key ForegroundNormal "#${ON_SURFACE}"
    dbus-send --session --dest=org.kde.KWin /KWin \
        org.kde.KWin.reloadConfig 2>/dev/null
    echo "[${MODULE}] KDE colours updated."
fi
