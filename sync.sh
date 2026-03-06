#!/bin/bash
# Sync current config into dotfiles repo and push
cd ~/dotfiles

cp -r ~/.config/hypr/custom/* hypr/custom/
cp ~/.config/hypr/hypridle.conf hypr/
cp ~/.config/hypr/hyprlock.conf hypr/
cp ~/.local/bin/noctalia-apply.sh bin/
cp ~/.local/bin/noctalia-icons.sh bin/
cp ~/.local/bin/noctalia-borders-watch.sh bin/
cp ~/.local/bin/noctalia-cursors.sh bin/ 2>/dev/null
cp ~/.config/gtk-3.0/settings.ini config/gtk-3.0/
cp ~/.config/gtk-4.0/settings.ini config/gtk-4.0/
cp ~/.config/noctalia/colors.json config/noctalia/
cp ~/.config/noctalia/noctalia-apply.conf config/noctalia/ 2>/dev/null

git add .
git diff --cached --stat

read -p "Commit message: " msg
if [ -n "$msg" ]; then
    git commit -m "$msg"
    git push
    echo "Done — pushed to GitHub."
else
    echo "Aborted — no commit message given."
    git reset HEAD
fi
