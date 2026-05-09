#!/usr/bin/env bash
# Install all packages required by the niri setup.
# Re-running is safe: pacman -S --needed skips already-installed packages.

set -euo pipefail

OFFICIAL=(
    # niri + wayland session
    niri
    waybar
    swayidle
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    wl-clipboard
    cliphist
    grim
    slurp
    brightnessctl
    pavucontrol
    playerctl

    # wallpaper (provides swww)
    awww

    # terminal + launcher + notifications + lock
    kitty
    fuzzel
    mako
    hyprlock
    stow

    # japanese input
    fcitx5
    fcitx5-mozc
    fcitx5-gtk
    fcitx5-qt

    # fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-jetbrains-mono-nerd

    # editor
    emacs
    emacs-wayland

    # wifi-secret storage (kwallet under non-KDE niri sessions)
    kwallet
    kwallet-pam
    libsecret
    networkmanager
)

echo "==> Installing official packages with pacman"
sudo pacman -S --needed --noconfirm "${OFFICIAL[@]}"

echo "==> Done. (No AUR packages required.)"
