#!/bin/sh
# Translate fcitx5-remote's numeric state into a waybar-friendly glyph.
#   0 = fcitx5 not running / disabled for this app
#   1 = inactive (English / direct keyboard)
#   2 = active (Mozc converting)

case "$(fcitx5-remote 2>/dev/null)" in
    1) echo "EN" ;;
    2) echo "あ" ;;
    *) echo "—" ;;
esac
