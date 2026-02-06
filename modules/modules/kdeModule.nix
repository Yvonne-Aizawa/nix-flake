{ inputs, ... }:
{
  flake.nixosModules.kdeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkMerge [
        {
          # Enable Plasma
          services.desktopManager.plasma6.enable = true;

          # Default display manager for Plasma
          services.displayManager.sddm = {
            enable = true;

            # To use Wayland (Experimental for SDDM)
            wayland.enable = true;
          };

          # Optionally enable xserver
          services.xserver.enable = true;
        }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [
              ".local/share/kwalletd"
            ];
          };
        })
      ];
    };
}
