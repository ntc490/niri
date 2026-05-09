#!/usr/bin/env bash
# System-level configuration for the niri setup.
# Idempotent: safe to re-run.

set -euo pipefail

# 1. Idle / suspend behavior owned by systemd-logind.
#    Drop-in (rather than editing the stock file) so distro updates won't conflict.
LOGIND_DROPIN=/etc/systemd/logind.conf.d/10-niri-idle.conf
echo "==> Writing $LOGIND_DROPIN"
sudo install -d -m 0755 /etc/systemd/logind.conf.d
sudo tee "$LOGIND_DROPIN" >/dev/null <<'EOF'
# Niri setup: suspend after 30 minutes of session-wide idle.
# swayidle (started from niri) handles screen-lock and publishes IdleHint.
[Login]
IdleAction=suspend
IdleActionSec=30min
EOF

# Reload (NOT restart) — restarting kills every login session on the box.
echo "==> Reloading systemd-logind"
sudo systemctl reload systemd-logind

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

echo "==> system.sh done"
