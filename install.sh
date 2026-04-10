#!/bin/bash
# =============================================================================
# install.sh — Noctalia dotfiles installer
# Sets up the Noctalia theming pipeline on a fresh CachyOS/Arch system.
# Safe to re-run — all operations are idempotent.
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$HOME/.local/share/icons"
LOCAL_BIN="$HOME/.local/bin"

echo "==> Noctalia dotfiles installer"
echo "    Dotfiles dir: $DOTFILES_DIR"
echo ""

# --- 1. Dependencies ---------------------------------------------------------
echo "==> Installing dependencies..."

PACMAN_DEPS=(
    inotify-tools   # noctalia-borders-watch.sh
    ruby            # cursor SVG generation
    python3         # noctalia-kvantum.py
    jq              # JSON colour parsing in all modules
    qt6ct           # Qt6 theming
    python-pyqt6    # qt6ct runtime
)

sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

# kvantum-git preferred over kvantum (ABI fixes)
if ! pacman -Q kvantum-git &>/dev/null; then
    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm kvantum-git
    elif command -v paru &>/dev/null; then
        paru -S --needed --noconfirm kvantum-git
    else
        echo "    WARNING: kvantum-git not installed — install manually via AUR helper"
        echo "    Falling back to kvantum..."
        sudo pacman -S --needed --noconfirm kvantum
    fi
fi

echo "    Dependencies installed."
echo ""

# --- 2. Symlink scripts -------------------------------------------------------
echo "==> Symlinking scripts to $LOCAL_BIN..."
mkdir -p "$LOCAL_BIN"

for f in "$DOTFILES_DIR/bin/"*; do
    target="$LOCAL_BIN/$(basename "$f")"
    ln -sf "$f" "$target"
    echo "    linked: $target"
done

echo ""

# --- 3. Kvantum output directory ---------------------------------------------
echo "==> Setting up Kvantum theme directory..."
mkdir -p "$HOME/.config/Kvantum/noctalia-dark"

# Check Colloid source theme is present
if [ ! -d "$HOME/.config/Kvantum/Colloid" ]; then
    echo "    WARNING: Colloid Kvantum theme not found at ~/.config/Kvantum/Colloid/"
    echo "    Install via AUR: yay -S kvantum-theme-colloid-git"
    echo "    Or clone manually and copy to ~/.config/Kvantum/Colloid/"
else
    echo "    Colloid source theme found."
fi

echo ""

# --- 4. Icon source ----------------------------------------------------------
echo "==> Checking icon source..."

if [ ! -d "$ICONS_DIR/Tela-Noctalia-Source" ]; then
    echo "    WARNING: Tela-Noctalia-Source not found at $ICONS_DIR/Tela-Noctalia-Source"
    echo "    This must be set up manually:"
    echo "      1. Copy a Tela dark variant:"
    echo "         cp -r /usr/share/icons/Tela-dark $ICONS_DIR/Tela-Noctalia-Source"
    echo "      2. Normalise accent colour to #5294e2 throughout all SVGs"
    echo "    See THEMING.md for details."
else
    echo "    Tela-Noctalia-Source found."
fi

echo ""

# --- 5. Oreo cursors source --------------------------------------------------
echo "==> Checking cursor source..."

if [ ! -d "$HOME/oreo-cursors" ]; then
    echo "    Cloning oreo-cursors..."
    git clone https://github.com/nicehash/oreo-cursors "$HOME/oreo-cursors"
else
    echo "    oreo-cursors already present."
fi

echo ""

# --- 6. qt6ct configuration --------------------------------------------------
echo "==> Configuring qt6ct..."
mkdir -p "$HOME/.config/qt6ct/colors"

QT6CT_CONF="$HOME/.config/qt6ct/qt6ct.conf"
if [ ! -f "$QT6CT_CONF" ]; then
    cat > "$QT6CT_CONF" << CONF
[Appearance]
style=kvantum
icon_theme=Tela-Noctalia-Active
custom_palette=true
color_scheme_path=$HOME/.config/qt6ct/colors/noctalia.conf
CONF
    echo "    qt6ct.conf created."
else
    # Ensure style=kvantum and icon theme are set
    sed -i 's/^style=.*/style=kvantum/' "$QT6CT_CONF"
    sed -i 's/^icon_theme=.*/icon_theme=Tela-Noctalia-Active/' "$QT6CT_CONF"
    echo "    qt6ct.conf updated."
fi

echo ""

# --- 7. Flatpak GTK theming --------------------------------------------------
echo "==> Configuring Flatpak GTK filesystem access..."

if command -v flatpak &>/dev/null; then
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
    echo "    Flatpak GTK overrides set."
else
    echo "    Flatpak not installed — skipping."
fi

echo ""

# --- 8. Hyprland env check ---------------------------------------------------
echo "==> Checking Hyprland Qt environment..."

ENV_CONF="$HOME/.config/hypr/custom/env.conf"
if [ -f "$ENV_CONF" ]; then
    if grep -q "QT_QPA_PLATFORMTHEME" "$ENV_CONF"; then
        echo "    QT_QPA_PLATFORMTHEME already set in env.conf."
    else
        echo "    WARNING: QT_QPA_PLATFORMTHEME not found in $ENV_CONF"
        echo "    Add this line to $ENV_CONF:"
        echo "      env = QT_QPA_PLATFORMTHEME,qt6ct"
    fi
else
    echo "    WARNING: $ENV_CONF not found."
    echo "    Add this to your Hyprland env config:"
    echo "      env = QT_QPA_PLATFORMTHEME,qt6ct"
fi

echo ""

# --- 9. Autostart check ------------------------------------------------------
echo "==> Checking Hyprland autostart..."

EXECS_CONF="$HOME/.config/hypr/custom/execs.conf"
if [ -f "$EXECS_CONF" ]; then
    if grep -q "noctalia-borders-watch" "$EXECS_CONF"; then
        echo "    noctalia-borders-watch.sh already in execs.conf."
    else
        echo "    WARNING: noctalia-borders-watch.sh not found in $EXECS_CONF"
        echo "    Add this line to $EXECS_CONF:"
        echo "      exec-once = ~/.local/bin/noctalia-borders-watch.sh"
    fi
else
    echo "    WARNING: $EXECS_CONF not found."
    echo "    Add to your Hyprland execs config:"
    echo "      exec-once = ~/.local/bin/noctalia-borders-watch.sh"
fi

echo ""

# --- 10. First run ------------------------------------------------------------
echo "==> Running noctalia-apply.sh..."

if [ -f "$HOME/.config/noctalia/colors.json" ]; then
    bash "$LOCAL_BIN/noctalia-apply.sh"
    echo "    Theme applied."
else
    echo "    WARNING: ~/.config/noctalia/colors.json not found."
    echo "    This file is written by the Noctalia shell on first launch."
    echo "    Run noctalia-apply.sh manually after launching Noctalia."
fi

echo ""
echo "==> Installation complete."
echo ""
echo "Next steps:"
echo "  1. Ensure QT_QPA_PLATFORMTHEME=qt6ct is set in your Hyprland env.conf"
echo "  2. Ensure noctalia-borders-watch.sh is in your Hyprland execs.conf"
echo "  3. Install Colloid Kvantum theme if not already present"
echo "  4. Set up Tela-Noctalia-Source if not already present"
echo "  5. Log out and back in, or run: bash ~/.local/bin/noctalia-apply.sh"
echo ""
echo "See THEMING.md for full documentation."
