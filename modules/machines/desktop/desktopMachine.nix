{ inputs, self, ... }:
{
  flake.nixosConfigurations.desktopMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      self.nixosModules.desktopModule
      self.nixosModules.desktopHardware
      self.nixosModules.firefoxModule
      self.homeModules.firefoxModule
      self.nixosModules.vscodeModule
      self.nixosModules.claudeCodeModule
      self.nixosModules.preservationModule
      self.nixosModules.snapshotModule
      self.nixosModules.hyprlandModule
      self.nixosModules.kdeModule
      self.nixosModules.userModule
      self.nixosModules.gitModule
    ];
  };

  flake.nixosModules.desktopModule =
    { pkgs, lib, ... }:
    {

      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "24.11";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      preservation.enable = true;
      preservation.user = "yvonne";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.initrd.supportedFilesystems = [ "btrfs" ];
      boot.initrd.systemd.enable = true;
      boot.initrd.systemd.extraBin = {
        btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
        cut = "${pkgs.coreutils}/bin/cut";
        tac = "${pkgs.coreutils}/bin/tac";
      };
      boot.initrd.systemd.services.rollback-root = {
        description = "Rollback root subvolume to blank snapshot";
        wantedBy = [ "initrd.target" ];
        after = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /mnt
          mount -t btrfs /dev/disk/by-partlabel/disk-main-root /mnt -o subvol=/
          if [ -e /mnt/root ]; then
            # Delete nested subvolumes first (deepest first)
            btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | tac | while read subvol; do
              btrfs subvolume delete "/mnt/$subvol"
            done
            btrfs subvolume delete /mnt/root
          fi
          btrfs subvolume snapshot /mnt/root-blank /mnt/root
          umount /mnt
        '';
      };

      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/nvme0n1";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "512M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
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
