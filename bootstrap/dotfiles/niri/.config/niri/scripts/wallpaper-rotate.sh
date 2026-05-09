#!/bin/sh
# Rotate awww wallpaper from a directory at a fixed interval.
# Override defaults via env vars: WALLPAPER_DIR, WALLPAPER_INTERVAL (seconds).

DIR="${WALLPAPER_DIR:-$HOME/Wallpaper}"
INTERVAL="${WALLPAPER_INTERVAL:-900}"

# Wait up to 3s for awww-daemon's socket to be ready.
for _ in $(seq 1 30); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done

while true; do
    pic=$(find -L "$DIR" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | shuf -n 1)
    [ -n "$pic" ] && awww img "$pic"
    sleep "$INTERVAL"
done
