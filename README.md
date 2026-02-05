# NixOS Ephemeral Root Configuration

A NixOS flake configuration featuring an ephemeral root filesystem with btrfs snapshots. The root filesystem is wiped on every boot, providing a clean, reproducible system state while preserving user data through dedicated persistent storage.

## Features

- **Ephemeral Root**: Root filesystem (`/`) is reset to a blank state on every boot
- **Persistent Storage**: User data survives reboots via the `/persist` subvolume
- **Btrfs Snapshots**: Create, list, and rollback snapshots of persistent data
- **Automatic Pre-rebuild Snapshots**: System automatically snapshots before `nixos-rebuild`
- **Modular Design**: Uses flake-parts with import-tree for automatic module discovery
- **Application Preservation**: Firefox and VS Code data automatically preserved

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

1. On boot, the initrd deletes the current `/root` subvolume
2. A fresh snapshot is created from `/root-blank`
3. The system boots into a clean state
4. User data in `/persist` remains intact across reboots

## Installation

### Prerequisites

- A machine or VM with a disk available (default: `/dev/nvme0n1`)
- NixOS installer ISO booted

### Steps

1. Clone this repository:
   ```bash
   git clone <repo-url> /tmp/nix_flake
   cd /tmp/nix_flake
   ```

2. Partition and format the disk using disko:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake .#desktopMachine
   ```

3. Create the blank root snapshot (required for ephemeral root):
   ```bash
   # Mount btrfs filesystem root to access all subvolumes
   sudo mkdir -p /tmp/btrfs-root
   sudo mount /dev/nvme0n1p2 /tmp/btrfs-root -o subvol=/

   # Replace disko's empty subvolume with a snapshot of clean root
   sudo btrfs subvolume delete /tmp/btrfs-root/root-blank
   sudo btrfs subvolume snapshot /tmp/btrfs-root/root /tmp/btrfs-root/root-blank

   sudo umount /tmp/btrfs-root
   ```

4. Install NixOS:
   ```bash
   sudo nixos-install --flake .#desktopMachine
   ```

5. Reboot into your new system:
   ```bash
   sudo reboot
   ```

### Post-Installation

Enable preservation for your user by adding to your configuration:

```nix
preservation.enable = true;
preservation.user = "yourusername";
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

Edit `modules/machines/desktopMachine.nix` and modify:

1. The disko device:
   ```nix
   disk.main.device = "/dev/sda";  # or your target disk
   ```

2. The initrd rollback service (`boot.initrd.systemd.services.rollback-root`):
   - Update `after` to match your partition (e.g., `dev-sda2.device`)
   - Update the `mount` command to use the correct partition

## Commands Reference

```bash
nix flake check                    # Validate flake
nix flake show                     # List outputs
nix build .#nixosConfigurations.desktopMachine.config.system.build.toplevel
```

## License

MIT
