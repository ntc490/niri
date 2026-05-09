# Minimal Niri Setup Notes

## Goals

- Minimal but polished
- Calm, low-distraction environment
- Terminal + Emacs centric
- Good transparency support
- Japanese input support
- Avoid overengineering
- Keep KDE installed as fallback
- Avoid giant riced setups for now

---

# Current Direction

Stay on:

- Arch Linux
- Niri
- Kitty
- zsh + oh-my-zsh
- Emacs

Add only the missing pieces needed to make the system feel complete.

---

# Core Packages

## Niri ecosystem

```bash
sudo pacman -S \
    niri \
    waybar \
    swaylock \
    swayidle \
    swww \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    wl-clipboard \
    grim \
    slurp \
    brightnessctl \
    pavucontrol \
    playerctl
```

---

## Japanese input

```bash
sudo pacman -S \
    fcitx5 \
    fcitx5-mozc \
    fcitx5-gtk \
    fcitx5-qt
```

---

# Environment Variables

Create:

```text
~/.config/environment.d/im.conf
```

Contents:

```ini
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
```

Then reboot or relog.

---

# Kitty

Install:

```bash
sudo pacman -S kitty
```

Config location:

```text
~/.config/kitty/kitty.conf
```

Suggested minimal settings:

```conf
background_opacity 0.85
confirm_os_window_close 0
enable_audio_bell no
cursor_trail 1

font_size 12.0

linux_display_server wayland

window_padding_width 8
```

---

# Wallpaper

Install:

```bash
sudo pacman -S swww
```

Example startup:

```bash
swww init
swww img ~/Pictures/wallpapers/dark.png
```

---

# Waybar

Config locations:

```text
~/.config/waybar/config
~/.config/waybar/style.css
```

Keep it minimal:

- workspaces
- clock
- battery
- wifi
- audio

Avoid giant dashboards.

---

# Screen Lock

Lock manually:

```bash
swaylock
```

Example idle setup:

```bash
swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'systemctl suspend'
```

---

# Clipboard

Wayland clipboard tools:

```bash
wl-copy
wl-paste
```

Example:

```bash
echo hello | wl-copy
wl-paste
```

---

# Screenshots

Fullscreen:

```bash
grim shot.png
```

Selection:

```bash
grim -g "$(slurp)" shot.png
```

---

# Audio

GUI mixer:

```bash
pavucontrol
```

Media controls:

```bash
playerctl play-pause
playerctl next
playerctl previous
```

---

# Notifications

Skip for now unless needed.

No need to install a notification daemon immediately.

---

# GTK Theme

Do not obsess over themes yet.

Get workflow stable first.

Maybe later:
- Catppuccin
- Gruvbox
- Tokyo Night

But avoid spending days tweaking colors.

---

# Fonts

Recommended:

```bash
sudo pacman -S \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-jetbrains-mono-nerd
```

---

# Emacs Notes

Niri likely pairs well with Emacs because:

- calmer window model
- less workspace micromanagement
- fewer conflicting paradigms
- good for terminal/editor/browser workflows

Try not to duplicate Emacs functionality in the compositor.

---

# Suggested Philosophy

Avoid:

- giant shell ecosystems
- endless plugin chains
- overcomplicated bars
- excessive animations
- rebuilding your setup every week

Prefer:

- stability
- muscle memory
- clean keybindings
- minimal distractions
- consistent tooling across Linux/macOS

---

# Things To Experiment With Later

Maybe later:

- Dank Material Shell + Niri
- Walker launcher
- SwayNC
- custom lockscreen
- blur/shaders
- Btrfs snapshots
- Snapper integration

But not immediately.

---

# Most Important Thing

Spend time WORKING in the environment.

Do not spend all your time configuring the environment.

The goal is:
- coding
- terminal work
- writing
- browsing
- productivity

Not endlessly tuning Linux.
