#!/bin/bash
# =============================================================================
# install-icons.sh — icon themes for the Noctalia theming pipeline
# Installs Tela and Gruvbox Plus, builds Tela-Noctalia-Source, and restores the
# Gruvbox Plus folder-colour template. Safe to re-run.
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="${ICONS_DIR:-$HOME/.local/share/icons}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia"

aur_install() {
    if command -v yay &>/dev/null; then yay -S --needed "$@"
    elif command -v paru &>/dev/null; then paru -S --needed "$@"
    else echo "    No AUR helper (yay/paru) found. Install manually: $*"; return 1
    fi
}

echo "==> Tela icon theme"
if [ -d /usr/share/icons/Tela-dark ]; then
    echo "    Tela-dark already installed."
else
    aur_install tela-icon-theme-git
fi

echo "==> Gruvbox Plus icon theme"
if [ -d "$ICONS_DIR/Gruvbox-Plus-Dark" ] || [ -d /usr/share/icons/Gruvbox-Plus-Dark ]; then
    echo "    Gruvbox-Plus-Dark already present."
else
    aur_install gruvbox-plus-icon-theme-git
    if [ -d "$ICONS_DIR/Gruvbox-Plus-Dark" ] || [ -d /usr/share/icons/Gruvbox-Plus-Dark ]; then
        echo "    Gruvbox-Plus-Dark installed."
    else
        echo "    WARNING: Gruvbox-Plus-Dark not found after install. The icon switcher"
        echo "    will fall back to Tela until it is available."
    fi
fi

echo "==> Tela-Noctalia-Source"
mkdir -p "$ICONS_DIR"
SRC="$ICONS_DIR/Tela-Noctalia-Source"
if [ -f "$SRC/index.theme" ]; then
    echo "    Already present."
elif [ -d /usr/share/icons/Tela-dark ]; then
    echo "    Building from Tela-dark (about 210 MB, symlinks resolved)..."
    cp -rL /usr/share/icons/Tela-dark "$SRC" 2>/dev/null
    if [ -f "$SRC/index.theme" ]; then
        sed -i '/^FollowsColorScheme=true/d' "$SRC/index.theme"
        echo "    Built."
    else
        echo "    WARNING: copy failed. Check /usr/share/icons/Tela-dark."
    fi
else
    echo "    WARNING: Tela-dark not installed, cannot build the source theme."
fi

echo "==> Gruvbox Plus folder-colour template"
TPL_DIR="$STATE_DIR/community-templates/gruvbox-plus-icons"
SAVED="$DOTFILES_DIR/config/noctalia/community-templates/gruvbox-plus-icons/colors"
if [ -d "$TPL_DIR" ] && [ -f "$SAVED" ]; then
    cp "$SAVED" "$TPL_DIR/colors"
    echo "    Restored. Apply it with: noctalia msg templates-apply"
else
    echo "    Template not installed yet. In Noctalia, tick gruvbox-plus-icons"
    echo "    (Settings, Templates, Community Templates), then re-run this script."
fi
