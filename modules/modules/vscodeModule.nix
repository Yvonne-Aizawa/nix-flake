{ inputs, ... }:
{
  flake.nixosModules.vscodeModule =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        { environment.systemPackages = [ pkgs.vscode ]; }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [
              ".config/Code"
              ".vscode"
            ];
          };
        })
      ];
    };
}
