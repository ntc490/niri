# Power / Battery — Future Work

TLP is the first lever and is set up live. This doc tracks the next
items to try, in order of expected impact. None of these are urgent;
all can wait until after the trip (2026-05-14).

Hardware: ThinkPad X1 Carbon Gen 7 (`20QDCTO1WW`). Battery at ~80% of
design capacity at 2024 cycles — software won't recover what's lost,
just slow further wear and squeeze idle power.

---

## 1. Switch suspend mode to S3 deep sleep

**Why:** s2idle ("Modern Standby") drains 3-5%/hour in suspend on this
generation; S3 typically drains <1%/hour. S3 also has cleaner wake
behavior — fewer spurious wakes (we saw several in the journal under
s2idle).

**How:**

1. Edit kernel cmdline: `sudo $EDITOR /boot/loader/entries/<entry>.conf`
   (systemd-boot) or `/etc/default/grub` then `grub-mkconfig` (GRUB).
   Add to the options/cmdline:
   ```
   mem_sleep_default=deep
   ```
2. Reboot.
3. Verify: `cat /sys/power/mem_sleep` should show `s2idle [deep]`
   (square brackets on `deep`).
4. Test: `systemctl suspend` from a terminal, then resume. Confirm
   the lid still wakes it, Ctrl key still wakes it, and no weird
   battery drain over a few hours of suspend.

**Caveats:** Gen 7 X1 was the transition generation to Modern Standby.
S3 mostly works but a few firmware revisions have wake quirks. Revert
by removing `mem_sleep_default=deep` from the cmdline if anything is
flaky. The kernel always supports both modes — this just changes the
default.

---

## 2. powertop --auto-tune at boot

**Why:** powertop applies a grab-bag of safe runtime-PM tweaks
(USB autosuspend on individual devices, codec idle, NIC ASPM, etc.).
TLP covers most of the big ones, but powertop catches the long tail.
Marginal win individually, cumulative noticeable.

**How:** create a systemd service that runs `powertop --auto-tune` once
at boot:

```
sudo pacman -S powertop
sudo tee /etc/systemd/system/powertop.service <<EOF
[Unit]
Description=PowerTOP auto-tune

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable powertop.service
```

**Caveats:** auto-tune can occasionally make a peripheral (e.g.
a finicky USB mouse) drop out under load. Easy revert:
`systemctl disable powertop.service && reboot`.

---

## 3. Bluetooth off by default

If you don't use Bluetooth daily:

```
sudo systemctl disable bluetooth.service
```

Toggle on demand: `sudo systemctl start bluetooth`. Small idle saving,
but it adds up over a long session.

---

## 4. Charge-threshold tuning per use-case

Current TLP setting: 75-80% band. For a multi-day trip with limited
charging, temporarily allow full charge:

```
sudo tlp fullcharge BAT0      # one-time charge to 100%, then resume thresholds
# or
sudo tlp setcharge 90 95 BAT0 # set a higher band; resets on reboot
```

Permanent changes go in `/etc/tlp.d/00-niri.conf`.

---

## 5. PPD instead of TLP (only if you want a UI toggle)

`power-profiles-daemon` integrates with GNOME's tray toggle
(performance / balanced / powersave). Niri doesn't have a built-in
indicator for it but you could add one to waybar. TLP is more
aggressive by default; PPD is more user-facing. Mutually exclusive —
pick one.

Not recommending the switch — TLP is the right tool for this hardware
unless the toggle UX is a priority.

---

## Validation

After any change, check:

```
tlp-stat -s                  # service status
tlp-stat -b                  # battery details (incl. cycle count, thresholds)
tlp-stat -p                  # CPU/governor settings
upower -i $(upower -e | grep BAT)   # discharge rate (W) in real time
cat /sys/power/mem_sleep     # which suspend mode is active
```

Track battery life empirically: charge to threshold, unplug, note
percentage at a known time, check an hour later. Don't chase 0.1%
gains — the variance between workloads is bigger than most tweaks.
