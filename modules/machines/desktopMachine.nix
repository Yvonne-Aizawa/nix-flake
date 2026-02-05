{ inputs,self, ... }:
{

  flake.nixosConfigurations.desktopMachine = inputs.nixpkgs.lib.nixosSystem {
  modules = [
    self.nixosModules.desktopModule
    self.nixosModules.firefoxModule
  ];
  };
  flake.nixosModules.desktopModule =
    { pkgs, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";
      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };
    };
}
