{ inputs, ... }:
{
  flake.nixosModules.desktopHardware = import ../hardware/desktop.nix;
}
