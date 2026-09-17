#!/usr/bin/env bash
set -eu

WALL="${WALLPAPER_PATH:-}"
[ -n "$WALL" ] && [ -f "$WALL" ] || exit 0

if command -v matugen >/dev/null 2>&1; then
    matugen image "$WALL" --type scheme-content --mode dark --prefer saturation >/dev/null 2>&1 || true
    hyprctl reload >/dev/null 2>&1 || true
    ws_style=$(cat "$HOME/.cache/quickshell-ws-anim" 2>/dev/null || echo slide)
    hyprctl eval "hl.animation({ leaf = 'workspaces', enabled = true, speed = 5, bezier = 'wind', style = '$ws_style' })" >/dev/null 2>&1 || true
    pkill -USR1 kitty >/dev/null 2>&1 || true
    "$HOME/.config/keyboard/set-color-keyboard.sh" >/dev/null 2>&1 &
fi

sudo -n /usr/share/sddm/themes/caelestia/scripts/sync.sh --posthook >/dev/null 2>&1 || true
