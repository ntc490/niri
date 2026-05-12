#!/usr/bin/env bash
# System-level configuration for the niri setup.
# Idempotent: safe to re-run.

set -euo pipefail

# 1. Idle / suspend behavior is owned entirely by swayidle (configured in
#    niri/config.kdl). systemd-logind does NOT own the suspend timer here:
#    its IdleAction relies on the IdleHint property, which stays true while
#    the session is locked (input goes to hyprlock, not the compositor),
#    causing logind to re-suspend on every wake and stack lock prompts.
#    swayidle's own timer fires once per idle period and resets on activity.
#    HandleLidSwitch=suspend (logind's default) is left alone — lid close
#    still suspends, and swayidle's before-sleep ensures the screen is
#    locked when it does.

# 2. SDDM PAM hooks for kwallet auto-unlock.
#    KDE installs these via its own PAM file; on a non-KDE setup we add them ourselves.
#    Required so /usr/lib/pam_kwallet_init can read the login password from
#    PAM_KWALLET5_LOGIN and unlock the wallet without re-prompting.
PAM_FILE=/etc/pam.d/sddm
if [[ -f "$PAM_FILE" ]]; then
    if ! sudo grep -q 'pam_kwallet5.so' "$PAM_FILE"; then
        echo "==> Adding kwallet PAM hooks to $PAM_FILE"
        sudo tee -a "$PAM_FILE" >/dev/null <<'EOF'

# Niri setup: kwallet auto-unlock at login (for NetworkManager wifi secrets).
auth     optional   pam_kwallet5.so
session  optional   pam_kwallet5.so auto_start
EOF
    else
        echo "==> $PAM_FILE already has kwallet hooks; skipping"
    fi
else
    echo "==> $PAM_FILE not found (SDDM not installed?); skipping kwallet PAM hooks"
fi

# 3. Enable NetworkManager (used for wifi).
echo "==> Enabling NetworkManager"
sudo systemctl enable --now NetworkManager.service

# 4. TLP power management with ThinkPad charge thresholds.
#    Drop-in (rather than editing /etc/tlp.conf) so distro updates don't conflict.
TLP_DROPIN=/etc/tlp.d/00-niri.conf
echo "==> Writing $TLP_DROPIN"
sudo install -d -m 0755 /etc/tlp.d
sudo tee "$TLP_DROPIN" >/dev/null <<'EOF'
# TLP drop-in for the niri setup. Charge in a 75-80% band to slow battery wear.
# For a long trip, temporarily allow full charge:
#   sudo tlp fullcharge BAT0
# Everything else relies on TLP's ThinkPad-aware defaults.
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF

echo "==> Enabling tlp.service"
sudo systemctl enable --now tlp.service

# TLP recommends masking systemd-rfkill so it owns the radio state.
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

echo "==> system.sh done"
