#!/usr/bin/env bash
set -euo pipefail

# Keep Super+R tied to the user's existing wallpaper collection.
wallpapers_dir="$HOME/.config/wallpapers"
if ! IFS= read -r -d '' selected_wallpaper < <(
    find -L "$wallpapers_dir" -type f ! -name 'preview_*' \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.webp' -o -iname '*.avif' -o -iname '*.bmp' \
        -o -iname '*.gif' -o -iname '*.svg' \) -print0 | shuf -z -n 1
); then
    notify-send 'Wallpaper' "No images found in $wallpapers_dir"
    exit 1
fi

exec qs -c ii ipc call wallpapers apply "$selected_wallpaper"
