{ inputs, ... }:
{
  flake.nixosModules.hyprlandModule =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        { programs.hyprland.enable = true;
        environment.systemPackages = [
pkgs.kitty
	]; }
      ];
    };

}
