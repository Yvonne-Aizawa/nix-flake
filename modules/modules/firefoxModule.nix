{ inputs, ... }:
{
  flake.nixosModules.firefoxModule =
    {
      config,
      lib,
      self,
      ...
    }:
    {
      config = lib.mkMerge [
        {
          programs.firefox.enable = true;
          programs.firefox.policies = {
            BlockAboutConfig = false;
          };
        }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [ ".config/mozilla" ];
          };
        })
      ];
    };
  flake.homeModules.firefoxModule = {

  };
}
