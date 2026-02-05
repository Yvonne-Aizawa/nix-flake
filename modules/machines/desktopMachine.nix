{ inputs, self, ... }:
{
  flake.nixosConfigurations.desktopMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      self.nixosModules.desktopModule
      self.nixosModules.firefoxModule
      self.nixosModules.preservationModule
    ];
  };

  flake.nixosModules.desktopModule =
    { pkgs, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";

      boot.loader.grub.enable = true;

      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/sda";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  size = "1M";
                  type = "EF02"; # BIOS boot partition for GRUB
                };
                root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };
        };
      };
    };
}
