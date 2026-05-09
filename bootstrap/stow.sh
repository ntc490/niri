#!/usr/bin/env bash
# Symlink config files into $HOME using GNU stow.
# Each subdirectory of dotfiles/ is treated as a stow "package".

set -euo pipefail

cd "$(dirname "$0")/dotfiles"

PACKAGES=(
    niri
    waybar
    kitty
    fuzzel
    mako
    hypr
    swaylock
    fcitx5
    environment
    emacs
)

for pkg in "${PACKAGES[@]}"; do
    echo "==> stow $pkg"
    stow -t "$HOME" -v "$pkg"
done

echo "==> stow.sh done"
