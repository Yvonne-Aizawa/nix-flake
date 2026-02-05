#!/usr/bin/env bash
# Pull latest changes and rebuild NixOS
set -euo pipefail

cd /persist/flake
git pull
sudo nixos-rebuild switch --flake /persist/flake#desktopMachine
