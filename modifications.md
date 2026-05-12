# Niri Setup — Modifications Log

Reconstructed from session 448f9498 (the long working session that's now closed).
Source of truth: `~/.claude/projects/-home-ncrapo-git-niri/448f9498-…jsonl`
plus the current state of the touched files.

The aim is a minimal, dark, quiet desktop with Japanese input and good
terminal/Emacs ergonomics. No riced dashboards.

---

## 1. Niri (`~/.config/niri/config.kdl`)

Edited the stock niri config. Key changes:

- **Terminal bind**: `Mod+T` → `kitty` (replaced the default).
- **App launcher**: `Mod+Space` → `fuzzel` (was Super+D originally; moved to
  `Mod+Space` because that's the muscle memory from macOS, and fcitx's
  trigger key was moved off of it — see §8).
- **Lock**: `Super+Alt+L` → `~/.config/niri/scripts/lock.sh`.
- **Focus ring** muted: `width 1`, `active-color "#3d4a5c"` (dim slate
  blue) instead of the loud default. Border disabled.
- **Window rule** added: `geometry-corner-radius 12`,
  `clip-to-geometry true`, `draw-border-with-background false`. The last
  flag is what stops the focus ring from washing out kitty's transparency.
- **`prefer-no-csd`** enabled (lets niri draw the ring around windows
  rather than behind them, fixes the transparency problem).
- **Layout**: `gaps 8` (was bigger), `default-column-width proportion 0.5`.
- **Input**: `focus-follows-mouse max-scroll-amount="50%"` — sloppy
  focus, but only for windows at least half on-screen. Tried `0%`
  (focus only on fully-visible windows) and bare `focus-follows-mouse`
  (full sloppy) on 2026-05-09 before settling here.
- **`hotkey-overlay { skip-at-startup }`** so the cheat sheet stops
  showing on every login.
- **Startup spawns** added:
  - `spawn-sh-at-startup "LC_TIME=ja_JP.utf8 waybar"` — waybar with a
    Japanese locale so `%a` renders kanji weekdays.
  - `spawn-at-startup "awww-daemon"` and the wallpaper rotator script.
  - `spawn-at-startup "fcitx5" "-d"` — Japanese input daemon.
  - `spawn-at-startup "mako"` — notification daemon.
  - `spawn-at-startup "/usr/lib/pam_kwallet_init"` — bridges the PAM
    socket SDDM sets up (`PAM_KWALLET5_LOGIN`) to kwalletd6, which
    auto-unlocks the wallet at login. See §12.
  - `spawn-sh-at-startup "wl-paste --type text --watch cliphist store"`
    and the matching image variant — clipboard history.
  - `spawn-sh-at-startup "swayidle -w timeout 300 '…/lock.sh'
    idlehint 300 before-sleep '…/lock.sh &'"` — see §9 for why this
    looks the way it does.
- **Extra binds**:
  - `Mod+Shift+N` / `Mod+Ctrl+N` — `makoctl dismiss` / `dismiss --all`.
  - `Mod+Y` — clipboard history menu via cliphist + fuzzel.

Note: `awww` is the package name on this system (installed in place of
the original `swww` plan from `setup.md`). Same daemon model.

---

## 2. Waybar (`~/.config/waybar/`)

Created from scratch. Three files:

### `config`
- `modules-left: [niri/workspaces]`,
  `modules-center: [clock]`,
  `modules-right: [custom/fcitx5, network, pulseaudio, battery]`.
- Workspaces shown as dots (`•` / `●`) — minimal, no numbers.
- Clock formatted in Japanese: `{:L%m月%d日(%a) %H:%M}` with
  `locale: "ja_JP.utf8"`. (Year intentionally dropped per request.)
- Network: glyph-only (`󰖩` / `󰈁` / `󰖪`); click opens
  `nm-connection-editor`.
- Battery: nerd-font glyph cluster with charging-prefix glyph.
- `custom/fcitx5`: polls the script in §3 every 1s; click toggles input
  method (`fcitx5-remote -t`).

### `style.css`
Dark/translucent theme matched to the rest of the stack:
- `window#waybar` background `rgba(20,22,26,0.78)`.
- Active workspace marked with a thin slate-blue underline (`#5a8aa8`).
- Inactive items dimmed to `#5c6370`; battery turns amber/red at 20/10%.
- Tooltip styled to match (`#14161eee` bg, `#3d4a5c` border, rounded).
- Font: `JetBrainsMono Nerd Font` 12px (chosen for full Latin + glyph
  coverage; Noto Sans CJK JP is in the fallback chain).

### `scripts/fcitx5-status.sh`
Tiny wrapper around `fcitx5-remote`: prints `EN` when inactive, `あ`
when Mozc is converting, `—` when fcitx isn't running. Polled by waybar
every second.

---

## 3. Kitty (`~/.config/kitty/kitty.conf`)

- `font_family JetBrainsMono Nerd Font Mono`, `font_size 13.0`.
- `background_opacity 0.68` + `dynamic_background_opacity yes`.
- `selection_foreground/background = none` — reverse-video selection.
  Replaces the default solid-bright highlight that was destroying the
  transparency on the focused window.
- `super+u` / `super+shift+u` — toggle bg opacity (1.0 ↔ 0.68).
- `hide_window_decorations yes`, `confirm_os_window_close 0`,
  `enable_audio_bell no`, `cursor_trail 1`,
  `linux_display_server wayland`.
- Tweaks to keep resize working without decorations
  (`resize_debounce_time 0.1`, `resize_draw_strategy static`,
  `remember_window_size yes`, `input_delay 3`, `repaint_delay 10`).

---

## 4. Fuzzel (`~/.config/fuzzel/fuzzel.ini`)

Created. Dark, low-contrast, slightly translucent — chosen to stop the
launcher from blowing out the rest of the dimmed setup.

- `font=JetBrainsMono Nerd Font:size=11`, `prompt=" "`, `terminal=kitty`.
- `lines=10`, `width=40`, `horizontal-pad=16`, `vertical-pad=12`.
- Background `#14161eee` (semi-transparent), text `#c8ccd4`,
  selection `#2a2d33`, border `#3d4a5c`, `radius=8`.

---

## 5. Mako (`~/.config/mako/config`)

Created. Matched to the waybar/fuzzel palette.

- `Noto Sans 11`, dark bg `#14161eee`, slate border `#3d4a5c`,
  `border-radius=8`.
- `anchor=top-right`, `layer=overlay`, `default-timeout=5000`,
  `max-visible=5`.
- Critical urgency: red border `#ea6962`, no auto-timeout.

---

## 6. Lock screen (hyprlock + helper)

We tried swaylock/swaylock-effects first (config still present at
`~/.config/swaylock/config`) but the layout couldn't get clock and
multi-line contact info to behave, so the active stack is now hyprlock.

### `~/.config/niri/scripts/lock.sh`
Thin shim: `exec flock -n /run/user/$UID/hyprlock.lock hyprlock "$@"`.
Originally picked a random wallpaper and symlinked it; that machinery
was removed when we pinned a single image (see below). Kept as a
stable entry point so `niri/config.kdl` and the swayidle line don't
need updating if we re-add pre-/post-lock logic later.

The `flock -n` is a single-instance guard. swayidle's `timeout 300`
and `before-sleep` can both fire during one walk-away (and `before-sleep`
fires every time logind triggers a suspend, which can happen multiple
times if the laptop wakes spuriously from s2idle). Without the guard,
each invocation stacks a fresh hyprlock on top of the previous one,
and the user types the password once per stacked instance. Diagnosed
2026-05-09 after a session where three lock screens stacked from the
initial idle lock + two suspend cycles.

The manual lock binding is `Super+Alt+L`; `hotkey-overlay-title` says
"hyprlock" (was incorrectly labeled "swaylock" until 2026-05-09).

### `~/.config/hypr/hyprlock.conf`
- Background pinned to
  `/home/ncrapo/Wallpaper/dark/fractured-wallpaper-3840x1600.jpg`
  (absolute path; `~` expansion in hyprlock is unreliable across
  versions).
- Light visual softening only:
  `blur_passes=1`, `blur_size=4`, `brightness=1.0`, `contrast=1.0`,
  `vibrancy=0.0`. Earlier values (`passes=3`, `size=8`,
  `brightness=0.85`) drove the dark image into a near-black
  rectangle — this set keeps the polygon detail visible while still
  taking the edge off behind the labels.
- Big clock (`HH:MM`, 96px) above center.
- Date below clock in Japanese (`%Y年%m月%d日(%a)`, 22px,
  `Noto Sans CJK JP`).
- Password input field 320×56, slate outline, Japanese placeholder
  `<i>パスワード...</i>` and fail text `<i>$FAIL ・ もう一度</i>`.
- Bottom-of-screen contact label: name + `801-953-6938` on a separate
  line (the limitation we couldn't get past in swaylock).

### `~/.config/swaylock/config` (kept as fallback)
Equivalent visual setup using swaylock-effects:
`effect-blur=8x3`, `effect-vignette=0.5:0.5`, the same palette, and
`datestr` with full-width spaces (`　`) to fake separators on a single
line.

---

## 7. Wallpaper rotator (`~/.config/niri/scripts/wallpaper-rotate.sh`)

Loops every `WALLPAPER_INTERVAL` seconds (default 900 = 15 min), picks
a random image from `WALLPAPER_DIR` (default `~/Wallpaper`), and calls
`awww img`. Waits up to 3s on startup for the daemon's socket. Started
from niri's `spawn-at-startup`.

---

## 8. fcitx5 (`~/.config/fcitx5/config`)

Edited the trigger keys:

- `Hotkey/TriggerKeys` set to `Control+Alt+Super+space`,
  `Zenkaku_Hankaku`, `Hangul`. The point of the long combo was to
  free up `Mod+Space` for the launcher and avoid colliding with
  Emacs's `Ctrl+Space`.

You also created `~/.config/environment.d/im.conf` (per the original
setup notes) with the standard
`GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS/INPUT_METHOD/SDL_IM_MODULE=fcitx`
block.

---

## 9. Idle / suspend behavior

**Final design (2026-05-09):** `hypridle` (Hyprland's idle daemon)
owns the idle sequence and integrates with hyprlock via systemd
session-lock. Config: `~/.config/hypr/hypridle.conf`. niri spawns
it with a bare `spawn-at-startup "hypridle"`.

```
general {
    lock_cmd          = pidof hyprlock || hyprlock
    before_sleep_cmd  = loginctl lock-session
    after_sleep_cmd   = niri msg action power-on-monitors
    inhibit_sleep     = 2
}

listener { timeout = 300;  on-timeout = loginctl lock-session }
listener { timeout = 600;  on-timeout = niri msg action power-off-monitors
                           on-resume  = niri msg action power-on-monitors }
listener { timeout = 1800; on-timeout = systemctl suspend }
```

- 5 min  → `loginctl lock-session` → DBus Lock signal → hypridle's
  `lock_cmd` runs `pidof hyprlock || hyprlock`. Single instance by
  construction.
- 10 min → DPMS off via `niri msg action power-off-monitors`;
  restored on first wayland activity via the `on-resume` clause.
- 30 min → `systemctl suspend`. `before_sleep_cmd` fires the same
  DBus Lock; `inhibit_sleep = 2` makes hypridle hold the sleep
  inhibitor until the screen is actually locked, so there's no
  race between suspend and lock.
- Manual `Super+Alt+L` calls `lock.sh`, which is now a one-line
  shim (`exec loginctl lock-session`) that goes through the same
  DBus path.

**What didn't work, and why (history kept for context):**

1. *Two-timer swayidle (initial 2026-05-08):* swayidle ran both
   `timeout 300 lock` and `timeout 1800 suspend`. Race: walk back
   at T=29:55, start typing the password, suspend fires at T=30:00
   mid-keystroke.

2. *logind owns suspend, swayidle publishes IdleHint (2026-05-08):*
   moved suspend to logind via `IdleAction=suspend`,
   `IdleActionSec=30min`. Looked clean on paper — unlock would
   clear IdleHint, logind would cancel pending suspend. But while
   the session is locked the user's input goes to hyprlock, not
   niri's surfaces. swayidle's idle protocol still sees the
   session as idle, so IdleHint stays `true` indefinitely.
   Result: logind re-suspends ~24s after every wake because
   IdleHint never clears, and each before-sleep starts a fresh
   hyprlock racing with the user's password attempts. Diagnosed
   via journal showing 4 suspend cycles in ~50 minutes with only
   one walk-away. We added a flock single-instance guard to
   `lock.sh` to deal with the stacking, but the underlying
   feedback loop remained.

3. *swayidle owns everything (2026-05-09 afternoon):* removed
   logind's IdleAction, gave swayidle its own `timeout 1800
   systemctl suspend`. The race from #1 returned (theoretically
   once per idle period instead of N times like #2) and the DPMS
   `on-resume` didn't reliably wake the display while locked
   because input wasn't reaching niri's surfaces.

4. *hypridle (this iteration):* the canonical Hyprland-ecosystem
   pairing for hyprlock. Solves all three problems by construction
   — DBus session-lock dedupes triggers, `pidof` guards spawning,
   `inhibit_sleep` removes the suspend race, and hyprlock has its
   own input-aware DPMS handling for the locked-screen case.
   The in-place edits to `/etc/systemd/logind.conf`
   (`IdleAction=suspend`, `IdleActionSec=30min`) were reverted —
   nothing publishes IdleHint anymore, so they were dead code,
   but cleaner to remove.

**Lesson:** I kept reaching for swayidle because it was the
"sway-y" thing, then patching its rough edges. The hyprlock docs
explicitly recommend hypridle and have a four-line example that
gets all of this right out of the box. Should have looked there
first.

**Operational notes:**

- `sudo systemctl reload systemd-logind` (SIGHUP) to pick up
  `/etc/systemd/logind.conf` changes. **Never `restart`** — it
  kills every login session on the box, including the SDDM seat
  and your wayland socket. Doing that on 2026-05-08 caused a
  hard-reset.
- hypridle is started by niri's `spawn-at-startup` and reads its
  config on launch. To pick up `hypridle.conf` changes:
  `pkill hypridle; hypridle &` (or restart niri).

`HandleLidSwitch=suspend` (the systemd default) was left alone — lid
close still suspends, and `before-sleep` ensures the screen is locked
on resume.

---

## 10. Emacs (`~/.emacs.d/init.el`)

Two related changes near the top of the file (around lines 1–48):

- **TTY transparency**: a `make-frame-functions` hook that sets the
  `default` face background to `unspecified-bg` on TTY frames, so
  kitty's transparency shows through `emacs -nw`.
- **PGTK transparency**: `(set-frame-parameter nil 'alpha-background 80)`
  + `(add-to-list 'default-frame-alist '(alpha-background . 80))` so
  GUI emacs (under `emacs-wayland`) is translucent without fighting the
  theme's face colors the way `alpha` does.
- **Magit/diff face overrides**: explicit dark-but-readable backgrounds
  on `magit-diff-added/removed/context/hunk-heading/file-heading`
  (and their `-highlight` variants), plus matching `diff-mode` faces.
  This was necessary because once the frame is translucent, the
  default magit highlights blow out and hide the cursor line.

`emacs-pgtk` wasn't found in the repos; `emacs-wayland` is what we
ended up with for the GUI build.

---

## 11. Claude permissions (`.claude/settings.local.json`)

Project-local allowlist of bash commands that were approved during this
session — `pacman -Q*`, `fc-list/fc-match`, `awww query`, the lock and
wallpaper scripts under `~/.config/niri/scripts/`, swaylock test runs,
etc. Useful as a record of what got introspected; safe to prune.

---

## 12. Wifi / KWallet (in progress, awaiting reboot test)

NetworkManager wifi connections were configured with
`802-11-wireless-security.psk-flags=1` (agent-owned), meaning NM
expects to fetch the PSK from a running secret-service agent. With no
agent running, NM falls through to interactive prompts — the "PITA"
of re-entering the wifi password every session.

What we discovered while diagnosing (and what changed the earlier
"don't touch PAM, kwallet won't work" answer):

- `kwallet 6.25.0-1` and `kwallet-pam 6.6.4-1` are already installed
  (KDE pulled them in long ago).
- **`/etc/pam.d/sddm` already has the kwallet PAM lines** (`auth` and
  `session` phases, `pam_kwallet5.so auto_start`). The KDE installer
  wired this up — no PAM edits required from us.
- `PAM_KWALLET5_LOGIN=/run/user/1000/kwallet5.socket` is exported
  into the niri session by SDDM. Verified live.
- A wallet file exists at `~/.local/share/kwalletd/kdewallet.kwl`
  (created 2025-05-07 from KDE days).

The missing piece was that nothing was running
`/usr/lib/pam_kwallet_init` — the helper that reads from the PAM
socket and hands the login password to kwalletd6. Plasma autostarts
this via `/etc/xdg/autostart/pam_kwallet_init.desktop` but niri (with
`X-systemd-skip=true` in the entry) doesn't.

**Change made**:
`spawn-at-startup "/usr/lib/pam_kwallet_init"` added to
`~/.config/niri/config.kdl` (next to mako's spawn). No PAM edits, no
new packages.

**Status — awaiting reboot test**: a live test against the existing
PAM socket exited 0 but didn't auto-launch kwalletd6. That's expected
if the PAM listener forked at boot has timed out by now. The real
test is the next clean login.

**After the reboot, the validation steps are**:

1. `pgrep -af kwalletd6` — should show the daemon running once
   anything (NM, SSH agent, etc.) requests a secret.
2. Re-save the wifi password into the wallet so future boots are
   silent. From a kitty:
   ```
   nmcli con up n4nf      # or whatever your home network is
   ```
   The first time, NM will prompt for the PSK; it'll then write it
   into the wallet (because `psk-flags=1`).
3. Subsequent boots: niri starts → pam_kwallet_init unlocks the
   wallet with your login password → NM gets the PSK silently → wifi
   connects without prompting.

**Fallback if kwalletd6 still doesn't auto-unlock**: most likely
cause would be a kwallet5/6 protocol mismatch in this version of
`kwallet-pam` (the module is named `pam_kwallet5.so` but is supposed
to handle kwallet6). Two options at that point:

- Spawn `kwalletd6` directly from niri startup. It'll prompt for the
  wallet password once per session (one prompt instead of one per
  wifi attempt — still a big win).
- Switch to system-owned PSKs: `nmcli con modify <name>
  802-11-wireless-security.psk-flags 0` per connection. Stores the
  password mode-`0600 root:root` in
  `/etc/NetworkManager/system-connections/`. Plaintext on
  unencrypted disk; you previously declined this, but worth flagging.

---

## Packages

### AUR packages — authoritative

`pacman -Qm` is the source of truth (foreign = AUR). Full list at the
time of writing (2026-05-09):

```
airspyhf-git           r147.87cf12a-1     (pre-existing, SDR)
airspyhf-git-debug     r147.87cf12a-1     (dep of above)
freerdp2               2.11.7-5           (pre-existing, RDP client lib)
gtk2                   2.24.33-5          (pre-existing, legacy GTK)
kanata                 1.8.1-1            (pre-existing, keyboard remapper)
kanata-debug           1.8.1-1            (dep of above)
phonon-qt6-mpv         0.1.0-3            (pre-existing, KDE mpv backend)
preload                0.6.4-9            (pre-existing)
preload-debug          0.6.4-9            (dep of above)
python-grip-git        4.6.2.r586.…-1     (pre-existing, GitHub readme tool)
python-path-and-address 2.0.1-1           (pre-existing, dep of grip)
sddm-astronaut-theme   67.bf4d017-1       (pre-existing)
sddm-sugar-dark        1.2-1              (pre-existing)
swaylock-effects-debug 1.7.0.0-4          ← from this session, ORPHAN
visual-studio-code-bin 1.100.2-1          (pre-existing)
yay                    12.5.7-1           (pre-existing, AUR helper)
yay-debug              12.5.7-1           (dep of above)
zen-browser-bin        1.17.14b-1         (pre-existing)
```

**Niri-related AUR additions: just one** —
`swaylock-effects-debug`, installed 2026-05-08 22:18. The actual
`swaylock-effects` binary was uninstalled during the session when we
switched to hyprlock; its `-debug` companion was missed by the cleanup
and is currently orphaned. To remove:

```
yay -Rns swaylock-effects-debug
```

Verify with `pacman -Qm | grep swaylock` — should return nothing.

### Not from AUR (clarification of earlier notes)

- `awww` is in the **official `extra`** repo, not AUR. It "provides
  swww", which is why `setup.md` referred to swww.
- `hyprlock` is in **`extra`**, not AUR.
- `swaylock` (vanilla) was installed and then removed; not currently
  on the system.

### Official-repo packages used by this setup

Not authoritatively gathered here — they aren't pinned in dotfiles, so
just for orientation:
`niri`, `waybar`, `swayidle`, `kitty`, `fuzzel`, `mako`, `cliphist`,
`wl-clipboard`, `awww`, `hyprlock`, `fcitx5`, `fcitx5-mozc`,
`fcitx5-gtk`, `fcitx5-qt`, `noto-fonts-cjk`, `ttf-jetbrains-mono-nerd`,
`emacs`, `emacs-wayland`. Run `pacman -Qe` for the full explicit list.

Already installed via KDE: `kwallet 6.25.0-1`, `kwallet-pam 6.6.4-1`,
`libsecret 0.21.7-1`. We're using these for NetworkManager secrets
storage — see §12. `gnome-keyring` is not installed and isn't needed.

---

## Open / unfinished items

- **Wifi password storage** (kwallet path) — wired up but unverified;
  next reboot is the test. See §12 for the validation steps and
  fallback plan.
- **Lid-close resume UX**: behavior is correct on paper but worth
  validating end-to-end after the logind change above.
- **Emacs over the network**: discussed using emacs-pgtk + remote
  `emacs --daemon` over SSH — not set up yet.
