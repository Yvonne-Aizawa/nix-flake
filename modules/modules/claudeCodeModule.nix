{ inputs, ... }:
{
  flake.nixosModules.claudeCodeModule =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {

      config = lib.mkMerge [
        { environment.systemPackages = [ pkgs.claude-code ]; }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user} = {
              directories = [ ".claude" ];
              files = [ ".claude.json" ];
            };
          };
        })
      ];
    };
}
