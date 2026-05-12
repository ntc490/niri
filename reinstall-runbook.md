# Reinstall Runbook: LUKS + btrfs + Subvolumes (Copy-Install)

Migrate the current Arch install on `nvme0n1p6` onto a LUKS-encrypted
btrfs filesystem with subvolumes, preserving all current data (home,
configs, ssh/gpg keys, AUR packages, etc.) via an external-disk
intermediary.

**Target completion: Tuesday or Wednesday this week** (travel
Thursday morning). Sunday/Monday gives buffer to debug a failed boot.

---

## Before you start — checklist

- [ ] **External disk** with ≥ 128 GB free, healthy, USB 3 if possible.
      Filesystem: ext4 or btrfs (NTFS works but slow and finicky for
      Linux metadata).
- [ ] **Arch installer USB** (latest ISO from archlinux.org, written
      with `dd` or Ventoy). Test that it boots on this laptop before
      day-of.
- [ ] **Windows BitLocker recovery key saved** somewhere not on this
      laptop. Even if we're not touching nvme0n1p3, the partitioning
      tool may trigger BitLocker re-keying on next Windows boot.
      `https://account.microsoft.com/devices/recoverykey` if signed
      in with a Microsoft account.
- [ ] **A second device with network access** (phone, another laptop,
      tablet) for looking things up while this laptop is offline.
- [ ] **All open work saved and pushed.** Browser bookmarks/sessions
      synced to the cloud or exported. Anything in `/tmp` accepted as
      lost.
- [ ] **A printout or PDF of this runbook** on the second device,
      since you won't have it on the laptop mid-install.
- [ ] **2-4 hour block of uninterrupted time.**

---

## Phase 0: Layout plan

Partitions (Windows partitions untouched):

| Partition | What | Status |
|---|---|---|
| nvme0n1p1 | Windows EFI (vfat) | keep as-is |
| nvme0n1p2 | MS Reserved | keep as-is |
| nvme0n1p3 | Windows / BitLocker | keep as-is |
| nvme0n1p4 | Windows Recovery (ntfs) | keep as-is |
| nvme0n1p5 | Linux ESP (vfat, 1 GB) at /boot | **keep, may reformat** |
| nvme0n1p6 | Linux root (btrfs, 126 GB) | **WIPE → LUKS+btrfs** |
| nvme0n1p7 | swap (15.6 GB) | **WIPE → encrypted swap** |

btrfs subvolumes inside `/dev/mapper/cryptroot`:

| Subvolume | Mount point | Why |
|---|---|---|
| `@` | `/` | rolled back by snapper on bad upgrade |
| `@home` | `/home` | preserves user data across rollbacks |
| `@log` | `/var/log` | excluded from snapshots (don't snapshot journal churn) |
| `@cache` | `/var/cache` | excluded from snapshots (pacman cache, etc.) |
| `@snapshots` | `/.snapshots` | snapper's snapshot store |

LUKS:
- `nvme0n1p6` → LUKS2 container, name `cryptroot`, passphrase you'll type at every boot.
- `nvme0n1p7` → re-encrypted random-key swap via `/etc/crypttab`. No
  hibernation support, but you don't hibernate (zram + suspend covers it).

---

## Phase 1: Backup from the running system

Plug in the external disk. Find its block device (`lsblk`) — let's
call it `/dev/sdX1` here. Mount it:

```bash
sudo mkdir -p /mnt/ext
sudo mount /dev/sdX1 /mnt/ext
df -h /mnt/ext   # confirm space and the right disk
```

Rsync the root filesystem (excluding mounted special filesystems and
the external itself):

```bash
sudo rsync -aHAXSv --info=progress2 \
    --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*' \
    --exclude='/tmp/*' --exclude='/run/*' --exclude='/mnt/*' \
    --exclude='/media/*' --exclude='/lost+found' \
    --exclude='/swapfile' \
    / /mnt/ext/root/
```

Flags: `-a` archive, `-H` hardlinks, `-A` ACLs, `-X` xattrs (matters
for capabilities and selinux-style metadata), `-S` sparse files,
`-v --info=progress2` for visible progress.

Save package lists separately for sanity checks later:

```bash
pacman -Qqe > /mnt/ext/pkglist-explicit.txt   # explicitly-installed
pacman -Qqm > /mnt/ext/pkglist-foreign.txt    # AUR / foreign
sudo cp /etc/fstab /mnt/ext/fstab.old.txt
sudo cp /etc/mkinitcpio.conf /mnt/ext/mkinitcpio.conf.old.txt
```

Unmount cleanly:

```bash
sudo sync
sudo umount /mnt/ext
```

**Verify the backup is readable** — plug the external into a second
machine or remount and `ls /mnt/ext/root/home/ncrapo/`. If you can't
see your files now, do not proceed.

---

## Phase 2: Boot the Arch installer USB

1. Plug USB, reboot, F12 (ThinkPad boot menu) → select USB.
2. At the prompt, `loadkeys us` (or your layout).
3. Connect wifi: `iwctl`, then inside iwctl:
   ```
   station wlan0 connect <SSID>
   exit
   ```
   Confirm: `ping -c 2 archlinux.org`
4. Plug the external disk back in. `lsblk` to find it.
5. **Optional incremental sync** (catches anything that changed
   between Phase 1 and now — emails received this morning, etc.):
   ```bash
   mount /dev/sdX1 /mnt/ext
   # NOT changing /, just adding to the backup; -a no --delete
   rsync -aHAXSv --info=progress2 \
       --exclude=... [same excludes as Phase 1] \
       /run/oldroot/ /mnt/ext/root/    # if /run/oldroot mounted
   ```
   If you skipped this, current backup is from when you ran Phase 1.

---

## Phase 3: Partition + encrypt + format

**Look very carefully** at every `nvme0n1pX` reference. Wiping the
wrong partition wipes Windows. `lsblk -f` first, every time.

Swap is currently active from the live USB? Unlikely on USB, but
check: `swapon --show`. If anything points at nvme0n1, `swapoff -a`.

### 3.1 Partition table (no change — using existing partitions)

We're keeping the existing partition layout. If you want to enlarge
nvme0n1p6 by taking space from Windows, do that with `parted` first;
otherwise skip. (Reminder: do BitLocker shrink from Windows before
this, not from Linux.)

### 3.2 LUKS on nvme0n1p6

```bash
# Sanity: confirm the partition you're about to destroy.
lsblk -f /dev/nvme0n1p6
# Expected: FSTYPE=btrfs, UUID=ac5a13e9-... (the old one)

cryptsetup luksFormat --type luks2 /dev/nvme0n1p6
# Type YES (uppercase), then a passphrase you'll remember.
# Lose this passphrase = lose everything. Write it down somewhere safe.

cryptsetup open /dev/nvme0n1p6 cryptroot
# Re-enter the passphrase. Creates /dev/mapper/cryptroot.
```

### 3.3 btrfs on the LUKS mapper

```bash
mkfs.btrfs -L arch /dev/mapper/cryptroot

# Mount top-level temporarily to create subvolumes
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

### 3.4 Mount everything in the layout we want

```bash
OPTS="noatime,compress=zstd:3,ssd,space_cache=v2"

mount -o "$OPTS,subvol=@"           /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,var/log,var/cache,.snapshots,boot}
mount -o "$OPTS,subvol=@home"       /dev/mapper/cryptroot /mnt/home
mount -o "$OPTS,subvol=@log"        /dev/mapper/cryptroot /mnt/var/log
mount -o "$OPTS,subvol=@cache"      /dev/mapper/cryptroot /mnt/var/cache
mount -o "$OPTS,subvol=@snapshots"  /dev/mapper/cryptroot /mnt/.snapshots

# ESP (existing, don't reformat unless it has cruft you want gone)
mount /dev/nvme0n1p5 /mnt/boot
```

Sanity check: `findmnt -R /mnt` should show 6 mounts on
`/dev/mapper/cryptroot[/@...]` plus `/mnt/boot` on `/dev/nvme0n1p5`.

---

## Phase 4: Restore data from external

```bash
mount /dev/sdX1 /mnt/ext     # external again, if not still mounted

rsync -aHAXSv --info=progress2 /mnt/ext/root/ /mnt/
```

This puts:
- `/etc`, `/usr`, `/var`, `/root` into the `@` subvolume.
- `/home/ncrapo` into the `@home` subvolume (because `/mnt/home` is
  `@home` and rsync follows the mount tree).
- `/var/log` into the `@log` subvolume, `/var/cache` into `@cache`.

When done, `du -sh /mnt/{,home/,var/log/,var/cache/}` to confirm the
data landed in the right places (each subvolume has the size you'd
expect; not all data on a single one).

---

## Phase 5: Chroot and configure for the new layout

```bash
arch-chroot /mnt
```

Inside the chroot (prompt should now look like `[root@archiso /]#`):

### 5.1 mkinitcpio: add the `encrypt` hook

```bash
# Edit /etc/mkinitcpio.conf
# HOOKS line — add `encrypt` between `block` and `filesystems`:
# Before:  HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)
# After:   HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
$EDITOR /etc/mkinitcpio.conf

# Regenerate all initramfs images.
mkinitcpio -P
```

If `mkinitcpio` complains about a missing module or hook, fix it
before continuing. Common gotchas:
- `keyboard` and `keymap` should appear **before** `encrypt` so you
  can type the passphrase.
- If you use a non-US layout, ensure `KEYMAP=us` (or yours) in
  `/etc/vconsole.conf`.

### 5.2 fstab: new UUIDs

Get the new UUIDs:

```bash
blkid /dev/nvme0n1p6 /dev/mapper/cryptroot /dev/nvme0n1p5 /dev/nvme0n1p7
# Note down:
#   LUKS_UUID   = UUID of /dev/nvme0n1p6 (TYPE=crypto_LUKS)
#   ROOT_UUID   = UUID of /dev/mapper/cryptroot (TYPE=btrfs)
#   ESP_UUID    = UUID of /dev/nvme0n1p5 (vfat)
#   SWAP_DEV    = /dev/nvme0n1p7  (we'll set up encrypted swap)
```

Write `/etc/fstab` (replacing the old one):

```
# /etc/fstab — rewritten for LUKS+btrfs subvols
UUID=<ROOT_UUID>  /            btrfs  noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@           0 0
UUID=<ROOT_UUID>  /home        btrfs  noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@home      0 0
UUID=<ROOT_UUID>  /var/log     btrfs  noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@log       0 0
UUID=<ROOT_UUID>  /var/cache   btrfs  noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@cache     0 0
UUID=<ROOT_UUID>  /.snapshots  btrfs  noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@snapshots 0 0
UUID=<ESP_UUID>   /boot        vfat   defaults,noatime                                              0 2
/dev/mapper/swap  none         swap   defaults                                                      0 0
```

### 5.3 crypttab: encrypted swap with random key

```
# /etc/crypttab
swap   /dev/nvme0n1p7   /dev/urandom   swap,cipher=aes-xts-plain64,size=256
```

Each boot, the swap partition is reformatted with a random key — no
hibernation, but very clean security model. zram swap is configured
elsewhere (or via the `zram-generator` package) and remains.

### 5.4 Bootloader: systemd-boot

The existing 1 GB ESP at `/boot` is already configured for
systemd-boot from the previous install. Re-install to be safe:

```bash
bootctl install
```

Now write the loader entry:

```bash
$EDITOR /boot/loader/entries/arch.conf
```

Content:

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet
```

Optional fallback entry (boots into the larger fallback initramfs if
the regular one fails — useful for first boot):

```bash
$EDITOR /boot/loader/entries/arch-fallback.conf
```

```
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options cryptdevice=UUID=<LUKS_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
```

And the loader config (timeout + default entry):

```bash
$EDITOR /boot/loader/loader.conf
```

```
default  arch.conf
timeout  3
console-mode max
editor   no
```

### 5.5 Final sanity checks (still in chroot)

```bash
# initramfs has the encrypt hook
lsinitcpio /boot/initramfs-linux.img | grep -E 'encrypt|cryptsetup' | head
# Expect to see usr/lib/initcpio/hooks/encrypt and usr/lib/initcpio/install/encrypt

# fstab references match blkid
cat /etc/fstab
blkid

# bootloader entries are present
ls /boot/loader/entries/

# crypttab reference matches a real device
cat /etc/crypttab
```

---

## Phase 6: Reboot

```bash
exit                          # leave chroot
umount -R /mnt
swapoff -a 2>/dev/null
cryptsetup close cryptroot
reboot
```

Remove the USB stick when the screen goes dark.

**Expected boot sequence:**

1. systemd-boot menu appears (or boots straight to the entry).
2. Kernel + initramfs load, then **passphrase prompt** for cryptroot.
3. Type the LUKS passphrase. Brief pause.
4. systemd messages scroll, then SDDM (or auto-login) → niri.

If you get a passphrase prompt → success. If you get a "Cannot find
root device" error or drop to an emergency shell, see the next
section.

---

## Phase 7: Post-boot validation

Once you're back at the niri desktop:

```bash
# Confirm LUKS is active and root is the mapper
lsblk -f
findmnt /

# Subvols mounted as expected
findmnt -t btrfs

# Hypridle, kwallet, network, etc. still working
pgrep -af hypridle
pgrep -af kwalletd6   # might be empty until NM asks for wifi secret
nmcli connection show

# TLP still active
tlp-stat -s | head -5
tlp-stat -b           # confirm charge thresholds still 75/80

# Battery state sane
acpi -i
```

If anything is missing, refer to `modifications.md` and re-run
`~/git/niri/bootstrap/bootstrap.sh` — it's idempotent.

---

## If first boot fails

Don't panic — the data is still on the external disk.

1. Boot the Arch USB.
2. Connect to wifi (same `iwctl` flow).
3. Unlock and mount everything:
   ```bash
   cryptsetup open /dev/nvme0n1p6 cryptroot
   mount -o subvol=@           /dev/mapper/cryptroot /mnt
   mount /dev/nvme0n1p5 /mnt/boot
   arch-chroot /mnt
   ```
4. Fix the issue (almost always one of: missing `encrypt` hook,
   wrong UUID in the loader entry, wrong subvol name, wrong path in
   the initrd line). Regenerate initramfs if needed: `mkinitcpio -P`.
5. Exit chroot, `umount -R /mnt`, reboot.

**Nuclear rollback** (if you can't make it boot and the trip is
looming): boot the Arch USB, wipe the LUKS container with
`wipefs -a /dev/nvme0n1p6`, recreate a plain btrfs on it
(`mkfs.btrfs -f /dev/nvme0n1p6`), rsync the backup back onto it,
chroot, restore the old `fstab` (you saved it as
`/mnt/ext/fstab.old.txt`), `mkinitcpio -P`, reinstall systemd-boot
without the `cryptdevice` cmdline. You're back to where you started,
unencrypted. Plan for another attempt after the trip.

**Keep `/mnt/ext` intact for at least a week** after the migration.
Don't reuse the external disk until you've confirmed everything
works.

---

## Optional follow-ups (after the trip)

These are nice-to-haves; not for the pre-Thursday push.

### TPM auto-unlock (skip the passphrase on every boot)

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p6
```

Then in `/boot/loader/entries/arch.conf`, add `rd.luks.options=tpm2-device=auto`
to the `options` line, regenerate initramfs, reboot. Caveat: PCR
binding means a BIOS update or secure-boot change re-locks the
volume and you fall back to the passphrase. Don't TPM-enroll unless
the passphrase is stored somewhere durable.

### Snapper for pre-upgrade snapshots

```bash
sudo pacman -S snapper snap-pac grub-btrfs
sudo snapper -c root create-config /
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

Now every `pacman -Syu` takes a pre/post snapshot. Roll back via
`snapper rollback` or by booting a snapshot from systemd-boot
(requires extra config; the grub-btrfs analog for systemd-boot is
`limine` or manual entries).

### Folding into bootstrap

After validating the new install works, update
`~/git/niri/bootstrap/system.sh` to document the LUKS+btrfs layout
as a prerequisite (assumed-already-done by the installer, not
performed by the script).
