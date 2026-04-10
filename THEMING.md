# Noctalia Theming System

Automatic colour theming for CachyOS / Hyprland / Noctalia Shell.
Recolours borders, icons, cursors, Qt/KDE apps, and GTK Flatpaks to match the
active Noctalia colour scheme.

## How It Works

Noctalia writes the current colour scheme to `~/.config/noctalia/colors.json`.
A watcher script (`noctalia-borders-watch.sh`) monitors that file for changes
and triggers the apply script automatically whenever the colour scheme changes.
The apply script reads the colours once and passes them to all modules:

```
colors.json → noctalia-apply.sh → noctalia-borders.sh
                                → noctalia-icons.sh
                                → noctalia-cursors.sh
                                → noctalia-qt.sh  (→ noctalia-kvantum.py)
                                → noctalia-pywal.sh  (optional)
```

## Colour Variables

`noctalia-apply.sh` exports these variables (without `#` prefix) for all modules:

| Variable | JSON key | Used for |
|---|---|---|
| `PRIMARY` | `mPrimary` | Cursor colour, border start, symbolic icon colour |
| `TERTIARY` | `mTertiary` | Folder icon colour, border end |
| `SURFACE` | `mSurfaceVariant` | Inactive border colour |
| `ON_SURFACE` | `mOnSurface` | Qt/KDE text colour |

## Scripts

### `noctalia-apply.sh`
Orchestrator. Reads `colors.json`, exports colour variables, runs enabled modules.
Always invoke modules through this script — running them standalone will result
in empty colour variables and broken output.

### `noctalia-borders.sh`
Sets Hyprland active/inactive border colours via `hyprctl keyword`.
Also syncs KDE highlight colour via `kwriteconfig6` if available.

### `noctalia-icons.sh`
Recolours Tela icon theme SVGs to match the current scheme.

**Colours replaced in SVGs:**
- `ColorScheme-Highlight` → `TERTIARY` (folder accent colour)
- `ColorScheme-Text` (`#aaaaaa`) → `PRIMARY` (symbolic/toolbar icon colour)
- `#5294e2`, `#5677fc` → `TERTIARY`

**Caching:** Recoloured sets cached at `~/.local/share/icons/Tela-Noctalia-<TERTIARY>-<PRIMARY>/`.
Cache key includes both colours so any scheme change invalidates stale caches.
Active theme always symlinked to `~/.local/share/icons/Tela-Noctalia-Active`.

**Source:** `~/.local/share/icons/Tela-Noctalia-Source` — do not modify cached
or Active variants directly.

### `noctalia-cursors.sh`
Generates Oreo cursor theme in `PRIMARY` colour, builds XCursor and hyprcursor
variants, applies via `hyprctl setcursor`.

**Caching:** Built themes cached at:
- `~/.local/share/icons/theme_oreo_noctalia_<hex>_hyprcursor/` (Hyprland)
- `~/.local/share/icons/oreo_noctalia_<hex>_cursors/` (GTK/XCursor)

First run for a new colour ~20 seconds. Subsequent runs instant.

**Requires:** `ruby`, `hyprcursor-util`, `oreo-cursors` repo at `~/oreo-cursors`

### `noctalia-qt.sh`
Themes all Qt/KDE applications via Kvantum + qt6ct + kdeglobals.

**Flow:**
1. Runs `noctalia-kvantum.py` to rewrite Kvantum SVG and kvconfig with current colours
2. Sets Kvantum theme to `noctalia-dark`
3. Writes qt6ct colour scheme from `colors.json`
4. Updates `qt6ct.conf` (style=kvantum, icon theme, colour scheme path)
5. Writes full KDE colour scheme to `kdeglobals` for Dolphin, Okular etc.

**Requires:** `kvantum-git`, `qt6ct`, `python3`, `jq`, `kwriteconfig6`

### `noctalia-kvantum.py`
Python script called by `noctalia-qt.sh`. Rewrites the Colloid Kvantum SVG and
kvconfig with Noctalia palette colours.

**What it replaces:**
- Surface/background colours in the SVG
- `[GeneralColors]` block in the kvconfig
- All `text.normal.color`, `text.focus.color`, `text.inactive.color` keys
  throughout all kvconfig sections — these are hardcoded in the Colloid source
  and must be replaced explicitly

**Source:** `~/.config/Kvantum/Colloid/ColloidDark.{svg,kvconfig}`
**Output:** `~/.config/Kvantum/noctalia-dark/noctalia-dark.{svg,kvconfig}`

### `noctalia-pywal.sh` (optional)
Writes a pywal-compatible `colors.json` to `~/.cache/wal/` and calls
`pywalfox update` for Firefox theming. Disabled by default.

### `noctalia-borders-watch.sh`
Watches `~/.config/noctalia/colors.json` with `inotifywait` and triggers
`noctalia-apply.sh` on change. Run at Hyprland startup via `exec-once`.

**Requires:** `inotify-tools`

## Setup

### 1. Dependencies

```bash
# Core
sudo pacman -S inotify-tools ruby kvantum-git qt6ct python3 jq kwriteconfig6

# Cursor generation
git clone https://github.com/nicehash/oreo-cursors ~/oreo-cursors

# Flatpak GTK theming — allow Flatpak apps to read your GTK theme
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
```

### 2. Symlink scripts

All scripts in `bin/` must be symlinked to `~/.local/bin/`:

```bash
for f in ~/dotfiles/bin/*; do
    ln -sf "$f" ~/.local/bin/"$(basename "$f")"
done
```

### 3. Icon source

`Tela-Noctalia-Source` must be present at `~/.local/share/icons/Tela-Noctalia-Source`.
This is a copy of a Tela colour variant with colour values normalised for recolouring.
It is not included in this repo due to size — copy any Tela dark variant and normalise:

```bash
cp -r /usr/share/icons/Tela-dark ~/.local/share/icons/Tela-Noctalia-Source
# Normalise: replace the variant's accent colour with #5294e2 throughout all SVGs
# (This is the base colour the recolouring script replaces)
```

### 4. Kvantum source theme

The Colloid Kvantum theme must be installed and present at
`~/.config/Kvantum/Colloid/`. Install via:

```bash
# From AUR
yay -S kvantum-theme-colloid-git
# Or manually clone and copy to ~/.config/Kvantum/Colloid/
```

Create the output directory:

```bash
mkdir -p ~/.config/Kvantum/noctalia-dark
```

### 5. Qt environment

In `~/.config/hypr/custom/env.conf` (or equivalent):

```
env = QT_QPA_PLATFORMTHEME,qt6ct
```

### 6. Autostart

In `~/.config/hypr/custom/execs.conf`:

```
exec-once = ~/.local/bin/noctalia-borders-watch.sh
```

### 7. First run

```bash
bash ~/.local/bin/noctalia-apply.sh
```

## Configuration

`~/.config/noctalia/noctalia-apply.conf` — enable/disable modules:

```bash
ENABLE_BORDERS=true
ENABLE_ICONS=true
ENABLE_CURSORS=true
ENABLE_QT=true
ENABLE_PYWAL=false
CURSOR_SIZE=28
```

`CURSOR_SIZE` must match `XCURSOR_SIZE` and `HYPRCURSOR_SIZE` in `env.conf`.

## Hyprland Cursor Environment

In `~/.config/hypr/custom/env.conf`, use the **compiled hyprcursor name**:

```
env = XCURSOR_THEME,oreo_noctalia_<hex>_cursors
env = XCURSOR_SIZE,28
env = HYPRCURSOR_THEME,theme_oreo_noctalia_<hex>_hyprcursor
env = HYPRCURSOR_SIZE,28
```

And in `execs.conf`:

```
exec-once = hyprctl setcursor theme_oreo_noctalia_<hex>_hyprcursor 28
```

The `theme_` prefix and `_hyprcursor` suffix are required — this is the compiled
directory name, not the XCursor name. Mixing them causes Hyprland to fall back
to its built-in cursor.

## Manual Trigger

```bash
bash ~/.local/bin/noctalia-apply.sh
```

Never run individual module scripts directly — `PRIMARY`, `TERTIARY`, `ON_SURFACE`
etc. are only exported by `noctalia-apply.sh`. Running a module standalone will
produce empty variables and broken/black icons.

## Clearing the Cache

Force a full rebuild after modifying source files or changing cursor size:

```bash
# Icons
rm -rf ~/.local/share/icons/Tela-Noctalia-*/
# Note: Source is preserved — only cached/Active variants are removed

# Cursors
rm -rf ~/.local/share/icons/oreo_noctalia_*/
rm -rf ~/.local/share/icons/theme_oreo_noctalia_*/

bash ~/.local/bin/noctalia-apply.sh
```

## Troubleshooting

**Symbolic/toolbar icons are white in Qt apps**
- Check `~/.config/qt6ct/qt6ct.conf` has `icon_theme=Tela-Noctalia-Active`
- Check `kreadconfig6 --file kdeglobals --group Icons --key Theme` returns `Tela-Noctalia-Active`
- Delete icon cache and rerun apply: `rm -rf ~/.local/share/icons/Tela-Noctalia-*[0-9a-f]*/`

**Flatpak apps (Warehouse, Evince etc.) are unthemed**
- Run: `flatpak override --user --filesystem=xdg-config/gtk-4.0:ro`
- Run: `flatpak override --user --filesystem=xdg-config/gtk-3.0:ro`
- Restart the app

**Qt app menus/text are wrong colour after scheme change**
- The kvantum kvconfig text colours are regenerated by `noctalia-kvantum.py`
- Run `bash ~/.local/bin/noctalia-apply.sh` and relaunch the app
- If still wrong, check `~/.config/Kvantum/noctalia-dark/noctalia-dark.kvconfig`
  for `text.normal.color` — should match `mOnSurface` from `colors.json`

**Folder icons are black after running icons script manually**
- `TERTIARY` is empty — always run via `noctalia-apply.sh`, never standalone

**Icon cache not updating after scheme change**
- Old cache dirs named `Tela-Noctalia-<hex>` (without ON_SURFACE suffix) may exist
- Remove them: `rm -rf ~/.local/share/icons/Tela-Noctalia-[0-9a-f]*/`
