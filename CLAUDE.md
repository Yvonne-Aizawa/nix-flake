# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS flake configuration using `flake-parts` and `import-tree` for automatic module discovery. Features an ephemeral root filesystem with btrfs snapshots for persistence and rollback.

## Architecture

**Flake Structure:**
- `flake.nix` - Entry point using flake-parts with import-tree to auto-import `modules/`
- `modules/modules/` - NixOS modules (exposed via `flake.nixosModules.<name>`)
- `modules/machines/` - Machine configurations (exposed via `flake.nixosConfigurations.<name>`)

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

**Application Module Pattern:**
Application modules should declare their own preservation needs using `mkMerge`:

```nix
{ config, lib, ... }:
{
  config = lib.mkMerge [
    { /* app config */ }
    (lib.mkIf config.preservation.enable {
      preservation.preserveAt."/persist" = {
        users.${config.preservation.user}.directories = [ ".app-data" ];
      };
    })
  ];
};
```

## Commands

```bash
nix flake check                    # Validate flake
nix flake show                     # List outputs
nix build .#nixosConfigurations.desktopMachine.config.system.build.toplevel
```

**Snapshot commands (on deployed system):**
```bash
snapshot [name]       # Create snapshot of /persist
snapshot-list         # List available snapshots
rollback <name>       # Restore /persist from snapshot (requires reboot)
snapshot-delete <name>
```
