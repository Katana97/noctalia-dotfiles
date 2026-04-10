#!/bin/bash
# =============================================================================
# noctalia-qt.sh — Qt/Kvantum theming module
#
# Flow:
#   1. Check deps (kvantummanager, python3, jq, kwriteconfig6)
#   2. Run noctalia-kvantum.py to regenerate SVG/kvconfig with current colours
#   3. Set Kvantum theme to noctalia-dark
#   4. Generate qt6ct colour scheme from colors.json
#   5. Write qt6ct config to use kvantum style + noctalia colour scheme
#   6. Write full KDE colour scheme to kdeglobals so KDE apps (Dolphin etc.)
#      pick up correct colours for toolbar, header, buttons etc.
#
# Expects: PRIMARY, TERTIARY, SURFACE, ON_SURFACE exported by noctalia-apply.sh
# Colors source: ~/.config/noctalia/colors.json
# =============================================================================

MODULE="qt"
KVANTUM_THEME="noctalia-dark"
COLORS_FILE="$HOME/.config/noctalia/colors.json"
QT6CT_DIR="$HOME/.config/qt6ct"
QT6CT_COLORS="$QT6CT_DIR/colors/noctalia.conf"
KVANTUM_PY="$HOME/.local/bin/noctalia-kvantum.py"

# --- Dependency checks -------------------------------------------------------
if ! command -v kvantummanager &>/dev/null; then
    echo "[${MODULE}] skipped — kvantummanager not found. Install with: sudo pacman -S kvantum"
    exit 0
fi

if ! command -v python3 &>/dev/null; then
    echo "[${MODULE}] skipped — python3 not found"
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "[${MODULE}] skipped — jq not found"
    exit 0
fi

# --- Regenerate Kvantum theme with current colours ---------------------------
if [ -f "$KVANTUM_PY" ]; then
    python3 "$KVANTUM_PY"
    echo "[${MODULE}] Kvantum SVG/kvconfig regenerated"
else
    echo "[${MODULE}] WARNING: noctalia-kvantum.py not found at $KVANTUM_PY"
fi

# --- Set Kvantum theme -------------------------------------------------------
if [ ! -d "$HOME/.config/Kvantum/${KVANTUM_THEME}" ]; then
    echo "[${MODULE}] ERROR: Kvantum theme '${KVANTUM_THEME}' not found"
    exit 1
fi

kvantummanager --set "$KVANTUM_THEME"
echo "[${MODULE}] Kvantum theme set to: ${KVANTUM_THEME}"

# --- Read colours from colors.json -------------------------------------------
surface=$(jq -r '.mSurface'           "$COLORS_FILE")
surface_var=$(jq -r '.mSurfaceVariant' "$COLORS_FILE")
on_surface=$(jq -r '.mOnSurface'      "$COLORS_FILE")
primary=$(jq -r '.mPrimary'           "$COLORS_FILE")
secondary=$(jq -r '.mSecondary'       "$COLORS_FILE")
tertiary=$(jq -r '.mTertiary'         "$COLORS_FILE")
outline=$(jq -r '.mOutline'           "$COLORS_FILE")
shadow=$(jq -r '.mShadow'             "$COLORS_FILE")
on_primary=$(jq -r '.mOnPrimary'      "$COLORS_FILE")
error=$(jq -r '.mError'               "$COLORS_FILE")

# Derived shades
surface_mid=$(jq -r '.mSurfaceVariant' "$COLORS_FILE")  # mid-tone between surface and surface_var

# --- Generate qt6ct colour scheme --------------------------------------------
mkdir -p "$QT6CT_DIR/colors"
cat > "$QT6CT_COLORS" << CONF
[ColorScheme]
# windowText,button,light,midlight,dark,mid,text,brightText,buttonText,base,window,shadow,highlight,highlightedText,link,linkVisited,alternateBase,NO_IDEA,toolTipBase,toolTipText,placeholderText,accent
active_colors=${on_surface}, ${surface_var}, #ffffff, ${outline}, ${shadow}, ${outline}, ${on_surface}, ${on_surface}, ${on_surface}, ${surface}, ${surface}, ${shadow}, ${primary}, ${on_primary}, ${secondary}, ${tertiary}, ${surface_var}, ${surface}, ${surface_var}, ${on_surface}, ${on_surface}, ${primary}
disabled_colors=${outline}, ${surface_var}, #ffffff, ${outline}, ${shadow}, ${outline}, ${outline}, ${outline}, ${outline}, ${surface}, ${surface}, ${shadow}, ${surface_var}, ${outline}, ${secondary}, ${tertiary}, ${surface_var}, ${surface}, ${surface_var}, ${outline}, ${outline}, ${surface_var}
inactive_colors=${on_surface}, ${surface_var}, #ffffff, ${outline}, ${shadow}, ${outline}, ${on_surface}, ${on_surface}, ${on_surface}, ${surface}, ${surface}, ${shadow}, ${surface_var}, ${on_surface}, ${secondary}, ${tertiary}, ${surface_var}, ${surface}, ${surface_var}, ${on_surface}, ${on_surface}, ${surface_var}
CONF
echo "[${MODULE}] qt6ct colour scheme written to $QT6CT_COLORS"

# --- Write qt6ct config ------------------------------------------------------
if [ -f "$QT6CT_DIR/qt6ct.conf" ]; then
    sed -i 's|^color_scheme_path=.*|color_scheme_path='"$QT6CT_COLORS"'|' "$QT6CT_DIR/qt6ct.conf"
    sed -i 's/^custom_palette=.*/custom_palette=true/' "$QT6CT_DIR/qt6ct.conf"
    sed -i 's/^style=.*/style=kvantum/' "$QT6CT_DIR/qt6ct.conf"
else
    cat > "$QT6CT_DIR/qt6ct.conf" << CONF
[Appearance]
style=kvantum
color_scheme_path=${QT6CT_COLORS}
custom_palette=true
CONF
fi
echo "[${MODULE}] qt6ct configured with noctalia colour scheme"

# --- Write KDE colour scheme to kdeglobals -----------------------------------
if ! command -v kwriteconfig6 &>/dev/null; then
    echo "[${MODULE}] WARNING: kwriteconfig6 not found, skipping kdeglobals update"
else
    _kw() {
        kwriteconfig6 --file kdeglobals --group "$1" --key "$2" "$3"
    }

    # Colors:Window
    _kw "Colors:Window" "BackgroundNormal"    "$surface"
    _kw "Colors:Window" "BackgroundAlternate" "$surface_var"
    _kw "Colors:Window" "ForegroundNormal"    "$on_surface"
    _kw "Colors:Window" "ForegroundInactive"  "$outline"
    _kw "Colors:Window" "ForegroundLink"      "$secondary"
    _kw "Colors:Window" "ForegroundVisited"   "$tertiary"
    _kw "Colors:Window" "ForegroundActive"    "$primary"
    _kw "Colors:Window" "ForegroundNegative"  "$error"
    _kw "Colors:Window" "DecorationFocus"     "$primary"
    _kw "Colors:Window" "DecorationHover"     "$primary"

    # Colors:Button
    _kw "Colors:Button" "BackgroundNormal"    "$surface_var"
    _kw "Colors:Button" "BackgroundAlternate" "$surface"
    _kw "Colors:Button" "ForegroundNormal"    "$on_surface"
    _kw "Colors:Button" "ForegroundInactive"  "$outline"
    _kw "Colors:Button" "ForegroundLink"      "$secondary"
    _kw "Colors:Button" "ForegroundVisited"   "$tertiary"
    _kw "Colors:Button" "ForegroundActive"    "$primary"
    _kw "Colors:Button" "ForegroundNegative"  "$error"
    _kw "Colors:Button" "DecorationFocus"     "$primary"
    _kw "Colors:Button" "DecorationHover"     "$primary"

    # Colors:View
    _kw "Colors:View" "BackgroundNormal"    "$surface"
    _kw "Colors:View" "BackgroundAlternate" "$surface_var"
    _kw "Colors:View" "ForegroundNormal"    "$on_surface"
    _kw "Colors:View" "ForegroundInactive"  "$outline"
    _kw "Colors:View" "ForegroundLink"      "$secondary"
    _kw "Colors:View" "ForegroundVisited"   "$tertiary"
    _kw "Colors:View" "ForegroundActive"    "$primary"
    _kw "Colors:View" "ForegroundNegative"  "$error"
    _kw "Colors:View" "DecorationFocus"     "$primary"
    _kw "Colors:View" "DecorationHover"     "$primary"

    # Colors:Selection
    _kw "Colors:Selection" "BackgroundNormal"    "$primary"
    _kw "Colors:Selection" "BackgroundAlternate" "$surface"
    _kw "Colors:Selection" "ForegroundNormal"    "$on_primary"
    _kw "Colors:Selection" "ForegroundInactive"  "$outline"
    _kw "Colors:Selection" "ForegroundLink"      "$secondary"
    _kw "Colors:Selection" "ForegroundVisited"   "$tertiary"
    _kw "Colors:Selection" "ForegroundActive"    "$on_primary"
    _kw "Colors:Selection" "ForegroundNegative"  "$error"
    _kw "Colors:Selection" "DecorationFocus"     "$primary"
    _kw "Colors:Selection" "DecorationHover"     "$primary"

    # Colors:Tooltip
    _kw "Colors:Tooltip" "BackgroundNormal"    "$surface_var"
    _kw "Colors:Tooltip" "BackgroundAlternate" "$surface"
    _kw "Colors:Tooltip" "ForegroundNormal"    "$on_surface"
    _kw "Colors:Tooltip" "ForegroundInactive"  "$outline"
    _kw "Colors:Tooltip" "DecorationFocus"     "$primary"
    _kw "Colors:Tooltip" "DecorationHover"     "$primary"

    # Colors:Header (toolbar text/icons)
    _kw "Colors:Header" "BackgroundNormal"    "$surface_var"
    _kw "Colors:Header" "BackgroundAlternate" "$surface"
    _kw "Colors:Header" "ForegroundNormal"    "$on_surface"
    _kw "Colors:Header" "ForegroundInactive"  "$outline"
    _kw "Colors:Header" "ForegroundLink"      "$secondary"
    _kw "Colors:Header" "ForegroundVisited"   "$tertiary"
    _kw "Colors:Header" "ForegroundActive"    "$primary"
    _kw "Colors:Header" "ForegroundNegative"  "$error"
    _kw "Colors:Header" "DecorationFocus"     "$primary"
    _kw "Colors:Header" "DecorationHover"     "$primary"

    # Colors:Complementary
    _kw "Colors:Complementary" "BackgroundNormal"    "$surface"
    _kw "Colors:Complementary" "BackgroundAlternate" "$surface_var"
    _kw "Colors:Complementary" "ForegroundNormal"    "$on_surface"
    _kw "Colors:Complementary" "ForegroundInactive"  "$outline"
    _kw "Colors:Complementary" "ForegroundActive"    "$primary"
    _kw "Colors:Complementary" "DecorationFocus"     "$primary"
    _kw "Colors:Complementary" "DecorationHover"     "$primary"

    # General
    kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "noctalia"
    kwriteconfig6 --file kdeglobals --group "General" --key "widgetStyle" "kvantum"

    # Notify running KDE apps
    dbus-send --session --dest=org.kde.KWin /KWin \
        org.kde.KWin.reloadConfig 2>/dev/null || true

    echo "[${MODULE}] kdeglobals KDE colour scheme updated"
fi

sed -i 's/^icon_theme=.*/icon_theme=Tela-Noctalia-Active/' "$QT6CT_DIR/qt6ct.conf"
echo "[${MODULE}] Qt theming applied. Relaunch Qt apps to pick up changes."

# --- Write KDE colour scheme to kdeglobals -----------------------------------
if command -v kwriteconfig6 &>/dev/null; then
    _kw() { kwriteconfig6 --file kdeglobals --group "$1" --key "$2" "$3"; }
    for group in "Colors:Window" "Colors:Button" "Colors:View" "Colors:Header" "Colors:Complementary" "Colors:Tooltip"; do
        _kw "$group" "BackgroundNormal"    "$surface"
        _kw "$group" "BackgroundAlternate" "$surface_var"
        _kw "$group" "ForegroundNormal"    "$on_surface"
        _kw "$group" "ForegroundInactive"  "$outline"
        _kw "$group" "ForegroundActive"    "$primary"
        _kw "$group" "DecorationFocus"     "$primary"
        _kw "$group" "DecorationHover"     "$primary"
    done
    _kw "Colors:Button" "BackgroundNormal" "$surface_var"
    _kw "Colors:Header" "BackgroundNormal" "$surface_var"
    _kw "Colors:Selection" "BackgroundNormal" "$primary"
    _kw "Colors:Selection" "ForegroundNormal" "$on_primary"
    kwriteconfig6 --file kdeglobals --group "General" --key "widgetStyle" "kvantum"
    dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reloadConfig 2>/dev/null || true
    echo "[${MODULE}] kdeglobals updated"
fi
