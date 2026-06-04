#!/bin/bash
# =============================================================================
# noctalia-gtk.sh — GTK symbolic icon colour module
#
# Noctalia rewrites ~/.config/gtk-{3,4}.0/noctalia.css on every scheme change,
# which wipes any manual additions. This script watches that file and appends
# a symbolic icon colour rule immediately after Noctalia rewrites it.
#
# Run at Hyprland startup via exec-once — do NOT call from noctalia-apply.sh.
#
# Requires: inotify-tools, jq
# =============================================================================

MODULE="gtk"
COLORS_FILE="$HOME/.config/noctalia/colors.json"
GTK4_CSS="$HOME/.config/gtk-4.0/noctalia.css"
GTK3_CSS="$HOME/.config/gtk-3.0/noctalia.css"

if ! command -v inotifywait &>/dev/null; then
    echo "[${MODULE}] skipped — inotifywait not found. Install: sudo pacman -S inotify-tools"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "[${MODULE}] skipped — jq not found. Install: sudo pacman -S jq"
    exit 1
fi

apply_gtk_icons() {
    local primary
    primary="$(jq -r '.mPrimary' "$COLORS_FILE")"

    for css in "$GTK4_CSS" "$GTK3_CSS"; do
        [ -f "$css" ] || continue
        # Remove any previous rule we added
        sed -i '/\/\* noctalia-symbolic-icons \*\//,/^}/d' "$css"
        # Append fresh rule
        cat >> "$css" << EOF
}

/* noctalia-symbolic-icons */
image.icon, .symbolic image, toolbutton image,
headerbar image, .toolbar image, button image,
treeview.view image {
    color: ${primary};
}
EOF
    done
    echo "[${MODULE}] Symbolic icon colour set to ${primary}"
}

# Apply once immediately on startup
apply_gtk_icons

# Then watch gtk-4.0 dir for future Noctalia rewrites
echo "[${MODULE}] Watching for scheme changes..."
while inotifywait -e close_write,moved_to,create \
    "$(dirname "$GTK4_CSS")" &>/dev/null; do
    [ -f "$GTK4_CSS" ] || continue
    # Re-apply if Noctalia wiped our rule
    if ! grep -q "noctalia-symbolic-icons" "$GTK4_CSS"; then
        apply_gtk_icons
    fi
done
