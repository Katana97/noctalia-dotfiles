#!/usr/bin/env python3
import re, os, json

def main():
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    colors_file = os.path.join(xdg_config_home, "noctalia", "colors.json")
    svg_path = os.path.join(xdg_config_home, "Kvantum", "Colloid", "ColloidDark.svg")
    kvconfig_src = os.path.join(xdg_config_home, "Kvantum", "Colloid", "ColloidDark.kvconfig")
    output_svg = os.path.join(xdg_config_home, "Kvantum", "noctalia-dark", "noctalia-dark.svg")
    output_kvconfig = os.path.join(xdg_config_home, "Kvantum", "noctalia-dark", "noctalia-dark.kvconfig")

    with open(colors_file) as f:
        c = json.load(f)

    primary     = c["mPrimary"]
    surface     = c["mSurface"]
    surface_var = c["mSurfaceVariant"]
    on_surface  = c["mOnSurface"]
    secondary   = c["mSecondary"]
    tertiary    = c["mTertiary"]
    error       = c["mError"]
    shadow      = c["mShadow"]
    on_primary  = c["mOnPrimary"]
    outline     = c["mOutline"]

    old_to_new = {
        '#1a1a1a': surface,
        '#1e1e1e': surface,
        '#212121': surface,
        '#242424': surface,
        '#26272a': surface,
        '#2c2c2c': surface,
        '#31363b': surface_var,
        '#3c3c3c': surface_var,
        '#5a616e': surface_var,
        '#525252': outline,
        '#5a5a5a': outline,
        '#646464': outline,
        '#666666': outline,
        '#989898': outline,
        '#acb1bc': outline,
        '#b6b6b6': outline,
        '#c1c1c1': outline,
        '#5b9bf8': primary,
        '#3daee9': primary,
        '#4285f4': primary,
        '#93cee9': secondary,
        '#b74aff': tertiary,
        '#dfdfdf': on_surface,
        '#eff0f1': on_surface,
        '#fcfcfc': on_surface,
        '#ffffff': on_surface,
        '#000000': shadow,
        '#f04a50': error,
    }

    with open(svg_path, 'r') as f:
        svg = f.read()
    for old, new in old_to_new.items():
        svg = re.sub(re.escape(old), new, svg, flags=re.IGNORECASE)
    with open(output_svg, 'w') as f:
        f.write(svg)

    with open(kvconfig_src, 'r') as f:
        kv = f.read()

    # Replace GeneralColors section
    general_colors = f"""[GeneralColors]
window.color={surface}
base.color={surface}
alt.base.color={surface_var}
button.color={surface_var}
light.color={outline}
mid.light.color={outline}
dark.color={shadow}
mid.color={surface_var}
highlight.color={primary}
inactive.highlight.color={surface_var}
text.color={on_surface}
window.text.color={on_surface}
button.text.color={on_surface}
disabled.text.color={outline}
tooltip.text.color={on_surface}
highlight.text.color={on_primary}
link.color={secondary}
link.visited.color={tertiary}
progress.indicator.text.color={on_primary}"""

    if '[GeneralColors]' in kv:
        kv = re.sub(r'\[GeneralColors\].*?(?=\[|\Z)', general_colors + '\n', kv, flags=re.DOTALL)
    else:
        kv += '\n' + general_colors + '\n'

    # Replace hardcoded text colours throughout all sections
    kv = re.sub(r'text\.normal\.color=#dfdfdf',   f'text.normal.color={on_surface}',  kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.normal\.color=#eff0f1',   f'text.normal.color={on_surface}',  kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.normal\.color=#fcfcfc',   f'text.normal.color={on_surface}',  kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.normal\.color=white',     f'text.normal.color={on_surface}',  kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.normal\.color=#ffffff',   f'text.normal.color={on_surface}',  kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.focus\.color=white',      f'text.focus.color={on_surface}',   kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.focus\.color=#ffffff',    f'text.focus.color={on_surface}',   kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.focus\.color=#dfdfdf',    f'text.focus.color={on_surface}',   kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.inactive\.color=#dfdfdf', f'text.inactive.color={outline}',   kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.inactive\.color=white',   f'text.inactive.color={outline}',   kv, flags=re.IGNORECASE)
    kv = re.sub(r'text\.inactive\.color=#ffffff', f'text.inactive.color={outline}',   kv, flags=re.IGNORECASE)

    with open(output_kvconfig, 'w') as f:
        f.write(kv)

    print("Kvantum noctalia-dark theme updated with Noctalia colours.")

if __name__ == "__main__":
    main()
