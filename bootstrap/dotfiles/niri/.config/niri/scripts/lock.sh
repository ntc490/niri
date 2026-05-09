#!/bin/sh
# Lock screen wrapper. The wallpaper is configured directly in
# ~/.config/hypr/hyprlock.conf — this shim exists so niri/swayidle
# have a single, stable entry point if we want to add pre/post-lock
# logic later.
#
# Single-instance via flock: swayidle's `timeout 300` and `before-sleep`
# can both fire in one idle period (idle → lock → suspend → wake →
# idle → lock → suspend → ...). Without a guard, each fires a fresh
# hyprlock that stacks on top of the previous one and the user has
# to type the password once per stacked instance. flock holds a lock
# for the lifetime of hyprlock; concurrent attempts exit immediately.
exec flock -n "/run/user/$(id -u)/hyprlock.lock" hyprlock "$@"
