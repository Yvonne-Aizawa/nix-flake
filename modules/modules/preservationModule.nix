{ inputs, ... }:
{
  flake.nixosModules.preservationModule =
    { config, lib, ... }:
    let
      cfg = config.preservation;
    in
    {
      imports = [ inputs.preservation.nixosModules.preservation ];

      options.preservation.user = lib.mkOption {
        type = lib.types.str;
        description = "Username for home directory preservation";
      };

      config = lib.mkIf cfg.enable {
        preservation.preserveAt."/persist" = {
          users.${cfg.user} = {
            directories = [
              "Documents"
            ];
          };
        };
      };
    };
}
