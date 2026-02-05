#!/usr/bin/env bash
# Step 1: Partition and format the disk using disko
set -euo pipefail

sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake .#desktopMachine
