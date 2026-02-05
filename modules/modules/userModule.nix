{ inputs, ... }:
{
  flake.nixosModules.userModule =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        {
          users.mutableUsers = false;

          users.users.root.initialPassword = "changeme";

          users.users.yvonne = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "changeme";
          };

          security.sudo.wheelNeedsPassword = true;
        }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.yvonne.directories = [
              ".ssh"
            ];
          };
        })
      ];
    };
}
