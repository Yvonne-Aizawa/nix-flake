#!/usr/bin/env bash
# Step 3: Install NixOS
set -euo pipefail

# Copy flake to persistent storage
sudo mkdir -p /mnt/persist/flake
sudo cp -r . /mnt/persist/flake/
sudo chown -R 1000:users /mnt/persist/flake

sudo nixos-install --flake .#desktopMachine
