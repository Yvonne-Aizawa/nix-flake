# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS flake configuration using `flake-parts` and `import-tree` for automatic module discovery.

## Architecture

**Flake Structure:**
- `flake.nix` - Main entry point using flake-parts with import-tree to auto-import everything under `modules/`
- `modules/` - All flake outputs organized by type:
  - `modules/modules/` - NixOS modules (exposed via `flake.nixosModules.<name>`)
  - `modules/machines/` - Machine configurations (exposed via `flake.nixosConfigurations.<name>`)
  - `modules/packages/` - Custom packages (would be exposed via `flake.packages`)

**Module Pattern:**
Each `.nix` file in `modules/` receives `{ inputs, self, ... }` and returns an attribute set that gets merged into the flake outputs. Use `flake.<output-type>.<name>` to add outputs:

```nix
{ inputs, self, ... }:
{
  flake.nixosModules.myModule = { pkgs, ... }: {
    # module configuration
  };
}
```

## Commands

```bash
# Check flake syntax and evaluate outputs
nix flake check

# Build a NixOS configuration
nix build .#nixosConfigurations.desktopMachine.config.system.build.toplevel

# List all flake outputs
nix flake show
```
