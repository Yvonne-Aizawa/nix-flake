{ inputs, ... }:
{
  flake.nixosModules.firefoxModule =
    { config, lib, ... }:
    {
      config = lib.mkMerge [
        { programs.firefox.enable = true; }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [ ".mozilla" ];
          };
        })
      ];
    };
}
