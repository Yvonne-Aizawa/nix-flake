{ inputs, ... }:
{
  flake.nixosModules.gitModule =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.git ];
    };
}
