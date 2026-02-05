# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS flake configuration using `flake-parts` and `import-tree` for automatic module discovery. Features an ephemeral root filesystem with btrfs snapshots for persistence and rollback.

## Architecture

**Flake Structure:**
- `flake.nix` - Entry point using flake-parts with import-tree to auto-import `modules/`
- `modules/modules/` - NixOS modules (auto-discovered, exposed via `flake.nixosModules.<name>`)
- `modules/machines/` - Machine configurations (exposed via `flake.nixosConfigurations.<name>`)

**Key Inputs:** nixpkgs (unstable), disko (disk partitioning), preservation (persistent state management)

**Module Pattern:**
Each `.nix` file receives `{ inputs, self, ... }` and returns an attribute set merged into flake outputs:

```nix
{ inputs, self, ... }:
{
  flake.nixosModules.myModule = { pkgs, lib, config, ... }: {
    # module configuration
  };
}
```

**Ephemeral Root + Preservation:**
The system uses btrfs subvolumes with root wiped on every boot:
- `/root` - Wiped on boot (restored from `/root-blank`)
- `/persist` - Persistent user data (managed by preservation module)
- `/nix` - Nix store
- `/snapshots` - Btrfs snapshots for rollback

Machine configs must set `preservation.enable = true` and `preservation.user = "<username>"` for preservation to work. User management is immutable (`users.mutableUsers = false`).

**Boot Configuration:**
- Uses UEFI with systemd-boot
- 512M EFI System Partition (FAT32) at `/boot`
- Default disk: `/dev/nvme0n1`

**Application Module Pattern:**
Application modules should declare their own preservation needs using `mkMerge`. Modules are auto-discovered but must be explicitly added to machine configurations:

```nix
{ inputs, ... }:
{
  flake.nixosModules.myAppModule = { config, lib, pkgs, ... }: {
    config = lib.mkMerge [
      { environment.systemPackages = [ pkgs.myapp ]; }
      (lib.mkIf config.preservation.enable {
        preservation.preserveAt."/persist" = {
          users.${config.preservation.user}.directories = [ ".config/myapp" ];
        };
      })
    ];
  };
}
```

Then add `self.nixosModules.myAppModule` to the machine's `modules` list.

## Commands

```bash
nix flake check                    # Validate flake
nix flake show                     # List outputs
nix build .#nixosConfigurations.desktopMachine.config.system.build.toplevel
```

**Rebuild (on deployed system):**
```bash
sudo nixos-rebuild switch --flake /persist/flake#desktopMachine
```

**Snapshot commands (on deployed system):**
```bash
snapshot [name]       # Create snapshot of /persist
snapshot-list         # List available snapshots
rollback <name>       # Restore /persist from snapshot (requires reboot)
snapshot-delete <name>
```

## Changing Target Disk

When changing from `/dev/nvme0n1` to another disk, update:
1. `modules/machines/desktopMachine.nix`:
   - `disko.devices.disk.main.device`
   - `boot.initrd.systemd.services.rollback-root` (after and mount command)
2. `step2.sh` - partition references
3. `modules/modules/snapshotModule.nix` - rollback script mount command
