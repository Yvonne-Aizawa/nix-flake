# NixOS Ephemeral Root Configuration

A NixOS flake configuration featuring an ephemeral root filesystem with btrfs snapshots. The root filesystem is wiped on every boot, providing a clean, reproducible system state while preserving user data through dedicated persistent storage.

## Features

- **Ephemeral Root**: Root filesystem (`/`) is reset to a blank state on every boot
- **Persistent Storage**: User data survives reboots via the `/persist` subvolume
- **Btrfs Snapshots**: Create, list, and rollback snapshots of persistent data
- **Automatic Pre-rebuild Snapshots**: System automatically snapshots before `nixos-rebuild`
- **Modular Design**: Uses flake-parts with import-tree for automatic module discovery
- **Application Preservation**: Firefox and VS Code data automatically preserved
- **UEFI Boot**: Uses systemd-boot with EFI System Partition

## Architecture

### Btrfs Subvolumes

| Subvolume | Mountpoint | Purpose |
|-----------|------------|---------|
| `/root` | `/` | Ephemeral root, wiped on boot |
| `/root-blank` | - | Clean snapshot used to reset root |
| `/persist` | `/persist` | Persistent user data |
| `/nix` | `/nix` | Nix store |
| `/snapshots` | `/snapshots` | Snapshot storage |

### How It Works

1. On boot, the initrd deletes the current `/root` subvolume (including nested subvolumes)
2. A fresh snapshot is created from `/root-blank`
3. The system boots into a clean state
4. User data in `/persist` remains intact across reboots

## Installation

### Prerequisites

- A UEFI machine or VM with a disk available (default: `/dev/nvme0n1`)
- NixOS installer ISO booted

### Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/Yvonne-Aizawa/nix-flake.git /tmp/nix_flake
   cd /tmp/nix_flake
   ```

2. Run the installation scripts in order:
   ```bash
   ./step1.sh    # Partition and format disk with disko
   ./step2.sh    # Create blank root snapshot and mount for install
   ./step3.sh    # Install NixOS (also copies flake to /persist/flake)
   ./step4.sh    # Reboot
   ```

### Post-Installation

The flake is available at `/persist/flake`. Rebuild with:

```bash
sudo nixos-rebuild switch --flake /persist/flake#desktopMachine
```

## Usage

### Snapshot Commands

Create a snapshot of `/persist`:
```bash
sudo snapshot [name]        # name defaults to timestamp
```

List available snapshots:
```bash
snapshot-list
```

Rollback to a previous snapshot:
```bash
sudo rollback <snapshot-name>
# Requires reboot to apply
```

Delete a snapshot:
```bash
sudo snapshot-delete <snapshot-name>
```

## Customization

### Adding Application Modules

Create a new module in `modules/modules/` that declares its own preservation needs:

```nix
{ inputs, ... }:
{
  flake.nixosModules.myAppModule =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        {
          # Application configuration
          environment.systemPackages = [ pkgs.myapp ];
        }
        (lib.mkIf config.preservation.enable {
          preservation.preserveAt."/persist" = {
            users.${config.preservation.user}.directories = [
              ".config/myapp"
            ];
          };
        })
      ];
    };
}
```

Then add it to your machine configuration in `modules/machines/desktopMachine.nix`:

```nix
modules = [
  # ... existing modules
  self.nixosModules.myAppModule
];
```

### Changing the Target Disk

The configuration uses partition labels (`/dev/disk/by-partlabel/disk-main-root`) which are portable. To change the disk device, edit:

1. `modules/machines/desktopMachine.nix`:
   ```nix
   disk.main.device = "/dev/sda";  # or your target disk
   ```

2. `step2.sh` - update partition references (e.g., `/dev/sda1`, `/dev/sda2`)

The partition labels and initrd rollback service do not need changes as they use disko-generated labels.

## Commands Reference

```bash
nix flake check                    # Validate flake
nix flake show                     # List outputs
nix build .#nixosConfigurations.desktopMachine.config.system.build.toplevel
```

## License

MIT
