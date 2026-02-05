{ inputs, ... }:
{
  flake.nixosModules.hyprlandModule =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        { programs.hyprland.enable = true; }
        environment.systemPackages = [pkgs.kitty];
	#(lib.mkIf config.preservation.enable {
        #  preservation.preserveAt."/persist" = {
        #    users.${config.preservation.user}.directories = [ ".mozilla" ];
        #  };
        #})
      ];
    };
}
