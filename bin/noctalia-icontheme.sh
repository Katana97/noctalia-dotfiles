#!/bin/bash
# noctalia-icontheme.sh — Gruvbox schemes use Gruvbox Plus icons, everything else uses Tela
MODULE="icontheme"
SETTINGS="$HOME/.local/state/noctalia/settings.toml"

# Read a key from the [theme] section of settings.toml
get() {
    awk -v k="$1" '/^\[theme\]/{t=1;next} /^\[/{t=0} t && $1==k {sub(/^[^=]*= *"/,""); sub(/".*/,""); print; exit}' "$SETTINGS"
}

SOURCE=$(get source)
MODE=$(get mode)
case "$SOURCE" in
    community) NAME=$(get community_palette) ;;
    builtin)   NAME=$(get builtin) ;;
    *)         NAME="" ;;
esac

ICON_THEME="Tela-Noctalia-Active"
case "${NAME,,}" in
    *gruvbox*)
        if [ "$MODE" = "light" ]; then WANT="Gruvbox-Plus-Light"; else WANT="Gruvbox-Plus-Dark"; fi
        if [ -d "$HOME/.local/share/icons/$WANT" ] || [ -d "/usr/share/icons/$WANT" ]; then
            ICON_THEME="$WANT"
        fi
        ;;
esac

kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME"
sed -i --follow-symlinks "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$HOME/.config/qt6ct/qt6ct.conf"
for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$f" ] && sed -i --follow-symlinks "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$f"
done
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null

echo "[${MODULE}] scheme='${NAME}' mode=${MODE} -> ${ICON_THEME}"
