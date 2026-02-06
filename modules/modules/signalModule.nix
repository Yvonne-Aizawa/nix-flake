{ inputs, ... }:
{
  flake.nixosModules.signalModule =
    {
      config,
      lib,
      self,
      ...
    }:
    {
      config = lib.mkMerge [
        { environment.systemPackages = [ pkgs.signal-desktop ]; }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [ ".config/Signal" ];
          };
        })
      ];
    };
  flake.homeModules.firefoxModule = {

  };
}
