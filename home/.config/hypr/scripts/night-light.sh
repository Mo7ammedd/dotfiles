#!/bin/sh

# Coordinate the original shortcut with end-4's running night-light service.
if qs -c ii ipc call preservedShortcuts toggleNightLight >/dev/null 2>&1; then
    exit 0
fi

if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset
    notify-send -a hyprsunset "Night light off"
    exit 0
fi

notify-send -a hyprsunset "Night light on" "Temperature: 4500 K"
exec hyprsunset --temperature 4500
