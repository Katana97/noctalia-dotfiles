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

**Theme naming:** Hyprland's hyprcursor format requires the `theme_` prefix and
`_hyprcursor` suffix. Your `env.conf` and `execs.conf` must use the full compiled
name, e.g. `theme_oreo_noctalia_76946a_hyprcursor`, not the XCursor name
`oreo_noctalia_76946a_cursors`. These are different formats serving different
purposes; mixing them up causes Hyprland to fall back to its built-in cursor.

**Cursor size:** Controlled by `CURSOR_SIZE` in `noctalia-apply.conf` (default: 28).
Must also match `XCURSOR_SIZE` and `HYPRCURSOR_SIZE` in `env.conf`.

**Requires:**
- `ruby` — SVG generation
- `hyprcursor-util` — hyprcursor compilation
- `oreo-cursors` repo cloned to `~/oreo-cursors`

#### Hotspot calibration

Hyprcursor hotspots are stored as fractions of the SVG canvas (0.0–1.0) and
are applied after scaling. They are **display-independent** — the same values
are correct at any cursor size or display DPI.

The hotspot table in `noctalia-cursors.sh` was derived by inspecting the oreo
SVG path geometry (all cursors use `viewBox="0 0 32 32"`) and empirically
verified. The key arrow cursor values are:

| Cursor | hotspot_x | hotspot_y | Notes |
|--------|-----------|-----------|-------|
| `default` / `left_ptr` | 0.1875 | 0.09375 | Tip at x≈6, y≈3 in SVG |
| `pointer` | 0.4375 | 0.125 | Fingertip at x≈14, y≈4 |
| `text` | 0.5 | 0.15625 | Beam top, centred horizontally |
| most others | 0.5 | 0.5 | Symmetric — centre is correct |

**To recalibrate** (e.g. after switching to a different cursor set):

1. Open a cursor SVG and find the visual tip coordinate in the path data
2. Divide by the viewBox size: `hotspot_x = tip_x / 32`, `hotspot_y = tip_y / 32`
3. Wipe the cache and rebuild:
   ```bash
   rm -rf ~/.local/share/icons/theme_oreo_noctalia_*_hyprcursor
   PRIMARY=<hex> ~/.local/bin/noctalia-cursors.sh
   ```
4. If still slightly off, adjust in single-pixel steps: `1/32 = 0.03125` per step

Note: the oreo SVG path for `default` starts at y=1.0 but the visual tip centre
sits at y≈3 due to stroke weight and anti-aliasing. Always verify empirically.

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
CURSOR_SIZE=28
```

The `CURSOR_SIZE` value here must match `XCURSOR_SIZE` and `HYPRCURSOR_SIZE` in
`~/.config/hypr/custom/env.conf`.

## Setup

### Autostart
Add to `~/.config/hypr/custom/execs.conf`:
```
exec-once = ~/.local/bin/noctalia-borders-watch.sh
```

### Hyprland cursor environment
In `~/.config/hypr/custom/env.conf`, use the **compiled hyprcursor name**:
```
env = XCURSOR_THEME,oreo_noctalia_<hex>_cursors
env = XCURSOR_SIZE,28
env = HYPRCURSOR_THEME,theme_oreo_noctalia_<hex>_hyprcursor
env = HYPRCURSOR_SIZE,28
```

And in `~/.config/hypr/custom/execs.conf`:
```
exec-once = hyprctl setcursor theme_oreo_noctalia_<hex>_hyprcursor 28
```

The `theme_` prefix and `_hyprcursor` suffix are required — this is the directory
name that `hyprcursor-util --create` produces, not the XCursor theme name.

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

To force a full rebuild (e.g. after modifying source icons or changing cursor size):

```bash
# Icons
rm -rf ~/.local/share/icons/Tela-Noctalia-*/
# (Tela-Noctalia-Source and Tela-Noctalia-Active will be recreated on next run)

# Cursors — both formats
rm -rf ~/.local/share/icons/oreo_noctalia_*/
rm -rf ~/.local/share/icons/theme_oreo_noctalia_*/

bash ~/.local/bin/noctalia-apply.sh
```
