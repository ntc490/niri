#!/bin/sh
# Lock screen entry point for the manual keybinding (Super+Alt+L).
# Delegates to systemd-logind's session-lock DBus mechanism: hypridle's
# `lock_cmd = pidof hyprlock || hyprlock` is registered as the handler,
# so it spawns hyprlock once and dedups concurrent triggers (idle timeout,
# before-sleep, manual bind) automatically.
exec loginctl lock-session
