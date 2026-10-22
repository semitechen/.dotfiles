#!/usr/bin/env bash
#
# setup-hibernation.sh: Configure Btrfs swapfile & suspend-then-hibernate for Framework 13 Pro
#
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo bash setup-hibernation.sh)" >&2
    exit 1
fi

ROOT_DEV="/dev/nvme0n1p2"
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV")
SWAP_DIR="/swap"
SWAP_FILE="$SWAP_DIR/swapfile"
SWAP_SIZE="34G"

echo ":: [1/7] Checking Btrfs subvolumes for @swap..."
MNT_DIR=$(mktemp -d)
mount -o subvolid=5 "$ROOT_DEV" "$MNT_DIR"

if [ ! -d "$MNT_DIR/@swap" ]; then
    echo ":: Creating @swap subvolume..."
    btrfs subvolume create "$MNT_DIR/@swap"
else
    echo ":: Subvolume @swap already exists."
fi
umount "$MNT_DIR"
rm -rf "$MNT_DIR"

mkdir -p "$SWAP_DIR"
if ! grep -qs "$SWAP_DIR" /etc/fstab; then
    echo ":: Adding @swap to /etc/fstab..."
    echo -e "UUID=$ROOT_UUID\t$SWAP_DIR\tbtrfs\trw,relatime,ssd,subvol=/@swap\t0 0" >> /etc/fstab
fi

if ! mountpoint -q "$SWAP_DIR"; then
    echo ":: Mounting $SWAP_DIR..."
    mount "$SWAP_DIR"
fi

echo ":: [2/7] Creating Btrfs swapfile ($SWAP_SIZE)..."
if [ ! -f "$SWAP_FILE" ]; then
    btrfs filesystem mkswapfile --size "$SWAP_SIZE" "$SWAP_FILE"
else
    echo ":: Swapfile $SWAP_FILE already exists."
fi

if ! grep -qs "$SWAP_FILE" /etc/fstab; then
    echo ":: Adding $SWAP_FILE to /etc/fstab (priority 10, keeping zram priority 100)..."
    echo -e "$SWAP_FILE\tnone\tswap\tdefaults,pri=10\t0 0" >> /etc/fstab
fi

echo ":: [3/7] Activating swapfile..."
swapon "$SWAP_FILE" 2>/dev/null || true

echo ":: [4/7] Calculating Btrfs resume offset..."
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r "$SWAP_FILE")
echo "   ↳ Resume UUID:   $ROOT_UUID"
echo "   ↳ Resume Offset: $RESUME_OFFSET"

echo ":: [5/7] Configuring kernel command line for hibernation resume..."
CMDLINE_FILE="/etc/kernel/cmdline"
if [ -f "$CMDLINE_FILE" ]; then
    cp -a "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    # Strip any existing resume parameters to prevent duplicates
    sed -i -E 's/[[:space:]]*resume=[^[:space:]]+//g; s/[[:space:]]*resume_offset=[^[:space:]]+//g' "$CMDLINE_FILE"
    # Append the new resume parameters
    sed -i -E "s/$/ resume=UUID=${ROOT_UUID} resume_offset=${RESUME_OFFSET}/" "$CMDLINE_FILE"
    echo "   ↳ Updated $CMDLINE_FILE"
fi

echo ":: [6/7] Updating mkinitcpio hooks for resume..."
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
if [ -f "$MKINITCPIO_CONF" ]; then
    cp -a "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
    if ! grep -q "resume" "$MKINITCPIO_CONF"; then
        # Add resume after filesystems or block
        sed -i 's/filesystems/filesystems resume/' "$MKINITCPIO_CONF"
        echo "   ↳ Added 'resume' hook to $MKINITCPIO_CONF"
    else
        echo "   ↳ 'resume' hook already present in $MKINITCPIO_CONF"
    fi
    echo "   ↳ Rebuilding Unified Kernel Image (UKI)..."
    mkinitcpio -P
fi

echo ":: [7/7] Configuring systemd suspend-then-hibernate (2h delay on battery)..."
mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d

cat << 'EOF' > /etc/systemd/sleep.conf.d/suspend-then-hibernate.conf
[Sleep]
HibernateDelaySec=2h
EOF

cat << 'EOF' > /etc/systemd/logind.conf.d/lid-suspend-then-hibernate.conf
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
EOF

systemctl restart systemd-logind 2>/dev/null || true

echo -e "\n\033[1;32m✓ Suspend-then-hibernate successfully configured on Framework 13 Pro!\033[0m"
echo "  Closing the lid will suspend immediately; after 2 hours on battery it will hibernate."
swapon --show
