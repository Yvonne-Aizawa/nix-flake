#!/usr/bin/env bash
# Step 3: Install NixOS
set -euo pipefail

sudo nixos-install --flake .#desktopMachine
