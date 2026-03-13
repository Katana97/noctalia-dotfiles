# Noctalia Dotfiles
CachyOS / Hyprland / Noctalia Shell configuration.

## Contents
- `hypr/custom/` — Hyprland keybinds and custom config
- `hypr/hypridle.conf` — Idle/lock screen config
- `hypr/hyprlock.conf` — Lock screen config
- `bin/` — Noctalia theming scripts
- `config/gtk-*/` — GTK theme settings
- `config/noctalia/` — Noctalia colours and apply config

## Theming
Noctalia includes an automatic colour theming system that recolours window
borders, folder icons, and cursors to match the active colour scheme.

See **[THEMING.md](THEMING.md)** for full documentation including setup,
dependencies, configuration, and cache management.

### Quick start
```bash
# Dependencies
sudo pacman -S inotify-tools ruby hyprcursor xorg-xcursorgen librsvg

# Cursor source repo
git clone https://github.com/nicehash/oreo-cursors ~/oreo-cursors

# Icon source (copy a Tela colour variant, normalise colour values)
# See THEMING.md for details

# Run manually
bash ~/.local/bin/noctalia-apply.sh

# Or add to ~/.config/hypr/custom/execs.conf:
# exec-once = ~/.local/bin/noctalia-borders-watch.sh
```

## Notes
- Hyprland config lives in a separate repo at `~/.config/hypr`
- Snapper snapshots are used for system-level rollback
- All theming scripts are safe to re-run — they are fully idempotent
