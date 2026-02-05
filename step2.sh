#!/usr/bin/env bash
# Step 2: Create the blank root snapshot (required for ephemeral root)
set -euo pipefail

# Mount btrfs filesystem root to access all subvolumes
sudo mkdir -p /tmp/btrfs-root
sudo mount /dev/nvme0n1p2 /tmp/btrfs-root -o subvol=/

# Replace disko's empty subvolume with a snapshot of clean root
sudo btrfs subvolume delete /tmp/btrfs-root/root-blank
sudo btrfs subvolume snapshot /tmp/btrfs-root/root /tmp/btrfs-root/root-blank

sudo umount /tmp/btrfs-root
