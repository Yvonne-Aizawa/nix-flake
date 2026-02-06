{ inputs, ... }:
{
  flake.nixosModules.openRgbModule =
    {
      config,
      lib,
      self,
      ...
    }:
    {
      config = lib.mkMerge [
        {
          services.hardware.openrgb.enable = true;
        }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [ ".config/OpenRGB" ];
          };
        })
      ];
    };
}
