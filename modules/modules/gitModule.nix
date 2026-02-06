{ inputs, ... }:
{
  flake.nixosModules.gitModule =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {

      config = lib.mkMerge [
        { environment.systemPackages = [ pkgs.git ]; }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user} = {
              directories = [ ".ssh/" ];
              files = [ ".gitconfig" ];
            };
          };
        })
      ];
    };
}
