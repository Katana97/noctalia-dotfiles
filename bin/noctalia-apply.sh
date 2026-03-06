#!/bin/bash
# =============================================================================
# noctalia-apply.sh — Noctalia theme orchestrator
# Reads colours.json and calls enabled modules in order.
# Modules: borders, icons, cursors
# Config:  ~/.config/noctalia/noctalia-apply.conf
# =============================================================================

COLORS_FILE="$HOME/.config/noctalia/colors.json"
CONFIG_FILE="$HOME/.config/noctalia/noctalia-apply.conf"
MODULES_DIR="$HOME/.local/bin"

# --- Defaults (overridden by config file) ------------------------------------
ENABLE_BORDERS=true
ENABLE_ICONS=true
ENABLE_CURSORS=true

# --- Load user config if present ---------------------------------------------
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# --- Sanity check ------------------------------------------------------------
if [ ! -f "$COLORS_FILE" ]; then
    echo "[noctalia-apply] ERROR: colors.json not found at $COLORS_FILE"
    exit 1
fi

# Check jq is available — everything depends on it
if ! command -v jq &>/dev/null; then
    echo "[noctalia-apply] ERROR: jq is not installed. Install with: sudo pacman -S jq"
    exit 1
fi

# --- Read colours once and export for all modules ----------------------------
export PRIMARY=$(jq -r '.mPrimary'        "$COLORS_FILE" | tr -d '#')
export TERTIARY=$(jq -r '.mTertiary'      "$COLORS_FILE" | tr -d '#')
export SURFACE=$(jq -r '.mSurfaceVariant' "$COLORS_FILE" | tr -d '#')
export ON_SURFACE=$(jq -r '.mOnSurface'   "$COLORS_FILE" | tr -d '#')

if [ -z "$PRIMARY" ] || [ "$PRIMARY" = "null" ]; then
    echo "[noctalia-apply] ERROR: Could not read colours from $COLORS_FILE"
    exit 1
fi

echo "[noctalia-apply] Theme colours: PRIMARY=#${PRIMARY} TERTIARY=#${TERTIARY}"

# --- Run enabled modules -----------------------------------------------------
run_module() {
    local name="$1"
    local script="$MODULES_DIR/noctalia-${name}.sh"
    if [ ! -f "$script" ]; then
        echo "[${name}] skipped — module script not found at $script"
        return
    fi
    bash "$script"
}

$ENABLE_BORDERS && run_module "borders"
$ENABLE_ICONS   && run_module "icons"
$ENABLE_CURSORS && run_module "cursors"

echo "[noctalia-apply] Done."
