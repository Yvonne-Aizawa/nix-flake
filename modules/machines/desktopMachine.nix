{ inputs, self, ... }:
{
  flake.nixosConfigurations.desktopMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      self.nixosModules.desktopModule
      self.nixosModules.firefoxModule
      self.nixosModules.vscodeModule
      self.nixosModules.preservationModule
      self.nixosModules.snapshotModule
      self.nixosModules.hyprlandModule
      self.nixosModules.userModule
    ];
  };

  flake.nixosModules.desktopModule =
    { pkgs, lib, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "24.11";

      preservation.enable = true;
      preservation.user = "yvonne";

      boot.loader.grub.enable = true;

      boot.initrd.postDeviceCommands = lib.mkBefore ''
        mkdir -p /mnt
        mount /dev/nvme0n1p2 /mnt -o subvol=/
        if [ -e /mnt/root ]; then
          btrfs subvolume delete /mnt/root
        fi
        btrfs subvolume snapshot /mnt/root-blank /mnt/root
        umount /mnt
      '';

      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/nvme0n1";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  size = "1M";
                  type = "EF02";
                };
                root = {
                  size = "100%";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "/root-blank" = { };
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "/snapshots" = {
                        mountpoint = "/snapshots";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
}
