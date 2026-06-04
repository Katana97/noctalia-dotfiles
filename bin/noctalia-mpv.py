#!/usr/bin/env python3
import json, re, sys
from pathlib import Path

COLORS_FILE = Path.home() / ".config/noctalia/colors.json"
UOSC_CONF = Path.home() / ".config/mpv/script-opts/uosc.conf"
MPV_CONF = Path.home() / ".config/mpv/mpv.conf"

def hex_to_rgb(h): return h.lstrip("#").upper()
def hex_to_ass(h):
    h=h.lstrip("#"); r,g,b=h[0:2],h[2:4],h[4:6]; return f"&H00{b}{g}{r}"

def load_colours():
    try:
        return json.load(open(COLORS_FILE))
    except FileNotFoundError:
        print(f"ERROR: not found: {COLORS_FILE}",file=sys.stderr); sys.exit(1)

def build_uosc_colour_string(c):
    fg  = hex_to_rgb(c.get("mOnSurface",        "#c8c093"))
    bg  = hex_to_rgb(c.get("mSurfaceVariant",          "#1f1f28"))
    dim = hex_to_rgb(c.get("mSurface",   "#16161d"))
    err = hex_to_rgb(c.get("mError",            "#c34043"))
    ok  = hex_to_rgb(c.get("mPrimary",          "#76946a"))
    acc = hex_to_rgb(c.get("mSecondary",        "#7e9cd8"))
    return f"foreground={fg},foreground_text={bg},background={bg},background_text={fg},curtain={dim},success={ok},error={err},match={acc}"

def update_uosc_conf(s):
    t = UOSC_CONF.read_text()
    u = re.sub(r"^color=.*$", f"color={s}", t, flags=re.MULTILINE)
    UOSC_CONF.write_text(u); print("✔ uosc updated")

def update_mpv_conf(c):
    fg = hex_to_ass(c.get("mOnSurface", "#c8c093"))
    bg = hex_to_ass(c.get("mSurfaceVariant",   "#1f1f28"))
    t  = MPV_CONF.read_text() if MPV_CONF.exists() else ""
    def roa(txt, k, v):
        p = rf"^{re.escape(k)}=.*$"
        return re.sub(p, f"{k}={v}", txt, flags=re.MULTILINE) if re.search(p, txt, flags=re.MULTILINE) else txt.rstrip()+f"\n{k}={v}\n"
    t = roa(t, "osd-color", fg); t = roa(t, "osd-border-color", bg)
    MPV_CONF.write_text(t); print("✔ mpv.conf updated")

def main():
    c = load_colours()
    update_uosc_conf(build_uosc_colour_string(c))
    update_mpv_conf(c)
    print("✔ noctalia-mpv complete")

main()
