# Noctalia Theming System

Automatic colour theming for CachyOS / Hyprland / Noctalia Shell.
Recolours borders, icons, and cursors to match the active Noctalia colour scheme.

## How It Works

Noctalia writes the current colour scheme to `~/.config/noctalia/colors.json`.
A watcher script (`noctalia-borders-watch.sh`) monitors that file for changes
and triggers the apply script automatically whenever the colour scheme changes.

The apply script reads the colours once and passes them to three modules:

```
colors.json → noctalia-apply.sh → noctalia-borders.sh
                                → noctalia-icons.sh
                                → noctalia-cursors.sh
```

## Scripts

### `noctalia-apply.sh`
Orchestrator. Reads `colors.json`, exports colour variables, runs enabled modules.

**Colours exported:**
- `PRIMARY` — used for cursor colour and border gradient start
- `TERTIARY` — used for icon colour and border gradient end
- `SURFACE` — used for inactive border colour
- `ON_SURFACE` — used for KDE selection foreground

### `noctalia-borders.sh`
Sets Hyprland active/inactive border colours via `hyprctl keyword`.
Also syncs KDE highlight colour via `kwriteconfig6` if available.

### `noctalia-icons.sh`
Recolours Tela icon theme SVGs to match `TERTIARY`.

**Caching:** Recoloured icon sets are cached at
`~/.local/share/icons/Tela-Noctalia-<hex>/`. On a cache hit the theme is
applied instantly. The active theme is always symlinked to
`~/.local/share/icons/Tela-Noctalia-Active`.

**Source:** Recolouring is done from `~/.local/share/icons/Tela-Noctalia-Source`.
Do not modify the Active or cached variants directly — edit the Source instead.

**Colours replaced:**
- `ColorScheme-Highlight` fill → `TERTIARY`
- `#5294e2` → `TERTIARY`
- `#5677fc` → `TERTIARY` (glyph folder icons)

### `noctalia-cursors.sh`
Generates Oreo cursor theme in `PRIMARY` colour, builds both XCursor (GTK
fallback) and hyprcursor variants, and applies via `hyprctl setcursor`.

**Caching:** Built themes are cached at:
- `~/.local/share/icons/theme_oreo_noctalia_<hex>_hyprcursor/` (Hyprland)
- `~/.local/share/icons/oreo_noctalia_<hex>_cursors/` (GTK/XCursor)

First run for a new colour takes ~20 seconds. Subsequent runs are instant.

**Requires:**
- `ruby` — SVG generation
- `hyprcursor-util` — hyprcursor compilation
- `oreo-cursors` repo cloned to `~/oreo-cursors`

### `noctalia-borders-watch.sh`
Watches `~/.config/noctalia/colors.json` with `inotifywait` and triggers
`noctalia-apply.sh` on change. Run at Hyprland startup via `exec-once`.

**Requires:** `inotify-tools`

## Configuration

`~/.config/noctalia/noctalia-apply.conf` — enable/disable modules and set cursor size:

```bash
ENABLE_BORDERS=true
ENABLE_ICONS=true
ENABLE_CURSORS=true
CURSOR_SIZE=32
```

## Setup

### Autostart
Add to `~/.config/hypr/custom/execs.conf`:
```
exec-once = ~/.local/bin/noctalia-borders-watch.sh
```

### Manual trigger
```bash
bash ~/.local/bin/noctalia-apply.sh
```

### Dependencies
```bash
sudo pacman -S inotify-tools ruby hyprcursor
git clone https://github.com/nicehash/oreo-cursors ~/oreo-cursors
```

### Icon source
The `Tela-Noctalia-Source` icon theme must be present at
`~/.local/share/icons/Tela-Noctalia-Source`. This is a copy of a Tela colour
variant with the colour values normalised ready for recolouring.

## Clearing the Cache

To force a full rebuild (e.g. after modifying source icons):

```bash
# Icons
rm -rf ~/.local/share/icons/Tela-Noctalia-*/
# (Tela-Noctalia-Source and Tela-Noctalia-Active will be recreated on next run)

# Cursors
rm -rf ~/.local/share/icons/oreo_noctalia_*/
rm -rf ~/.local/share/icons/theme_oreo_noctalia_*/

bash ~/.local/bin/noctalia-apply.sh
```
