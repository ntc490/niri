#!/usr/bin/env bash
# Top-level entry point for reproducing the niri setup on a clean system.
#
# Run order:
#   1. packages.sh — pacman installs (also installs `stow`, needed by step 2)
#   2. stow.sh     — symlink config files from dotfiles/ into $HOME
#   3. system.sh   — /etc edits (logind drop-in, SDDM PAM hooks, NM enable)
#
# Idempotent: re-running is safe.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ "$(uname -s)" != "Linux" ]] || ! command -v pacman >/dev/null 2>&1; then
    echo "This bootstrap targets Arch Linux. Aborting." >&2
    exit 1
fi

"$HERE/packages.sh"
"$HERE/stow.sh"
"$HERE/system.sh"

# Wallpaper directory used by the rotator script. Created empty if missing —
# the rotator handles that gracefully, but you'll want to drop images in.
if [[ ! -d "$HOME/Wallpaper" ]]; then
    echo "==> Creating empty $HOME/Wallpaper (drop images here)"
    mkdir -p "$HOME/Wallpaper"
fi

cat <<'EOF'

==> bootstrap.sh complete.

Next steps:
  - Reboot (or relog into a fresh niri session) so environment.d/im.conf,
    PAM hooks, and the logind drop-in all take effect.
  - Drop wallpaper images into ~/Wallpaper/.
  - Open fcitx5-configtool once to confirm Mozc is in the input-method list.
  - First wifi connection: `nmcli con up <ssid>` will prompt for the PSK once;
    kwallet stores it for subsequent boots.
EOF
