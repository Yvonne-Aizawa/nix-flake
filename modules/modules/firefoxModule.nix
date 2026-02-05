{ inputs, ... }:
{

  flake.nixosModules.firefoxModule =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;

    };

}
