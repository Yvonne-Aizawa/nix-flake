{ inputs, ... }:
{
  flake.nixosModules.snapshotModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      snapshotScript = pkgs.writeShellScriptBin "snapshot" ''
        set -euo pipefail

        SNAPSHOT_DIR="/snapshots"
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        NAME="''${1:-$TIMESTAMP}"

        if [ ! -d "$SNAPSHOT_DIR" ]; then
          echo "Error: $SNAPSHOT_DIR does not exist"
          exit 1
        fi

        echo "Creating snapshot: $NAME"
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r /persist "$SNAPSHOT_DIR/persist-$NAME"
        echo "Snapshot created: $SNAPSHOT_DIR/persist-$NAME"
      '';

      listSnapshotsScript = pkgs.writeShellScriptBin "snapshot-list" ''
        set -euo pipefail

        SNAPSHOT_DIR="/snapshots"

        echo "Available snapshots:"
        echo ""

        for snap in "$SNAPSHOT_DIR"/persist-*; do
          if [ -d "$snap" ]; then
            name=$(basename "$snap" | sed 's/^persist-//')
            created=$(${pkgs.btrfs-progs}/bin/btrfs subvolume show "$snap" 2>/dev/null | grep "Creation time" | cut -d: -f2- | xargs)
            echo "  $name  ($created)"
          fi
        done
      '';

      rollbackScript = pkgs.writeShellScriptBin "rollback" ''
        set -euo pipefail

        SNAPSHOT_DIR="/snapshots"

        if [ -z "''${1:-}" ]; then
          echo "Usage: rollback <snapshot-name>"
          echo ""
          echo "Available snapshots:"
          for snap in "$SNAPSHOT_DIR"/persist-*; do
            if [ -d "$snap" ]; then
              basename "$snap" | sed 's/^persist-/  /'
            fi
          done
          exit 1
        fi

        SNAPSHOT="$SNAPSHOT_DIR/persist-$1"

        if [ ! -d "$SNAPSHOT" ]; then
          echo "Error: Snapshot '$1' not found"
          exit 1
        fi

        echo "WARNING: This will replace /persist with snapshot '$1'"
        echo "A backup of current state will be saved as 'pre-rollback'"
        read -p "Continue? [y/N] " confirm

        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
          echo "Aborted"
          exit 1
        fi

        echo "Creating backup of current state..."
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r /persist "$SNAPSHOT_DIR/persist-pre-rollback-$(date +%Y%m%d-%H%M%S)"

        echo "Performing rollback..."
        # Mount the btrfs root to manipulate subvolumes
        TMPDIR=$(mktemp -d)
        mount /dev/disk/by-partlabel/disk-main-root "$TMPDIR" -o subvol=/

        # Delete current persist and restore from snapshot
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$TMPDIR/persist"
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$SNAPSHOT" "$TMPDIR/persist"

        umount "$TMPDIR"
        rmdir "$TMPDIR"

        echo "Rollback complete. Reboot to apply changes."
      '';

      deleteSnapshotScript = pkgs.writeShellScriptBin "snapshot-delete" ''
        set -euo pipefail

        SNAPSHOT_DIR="/snapshots"

        if [ -z "''${1:-}" ]; then
          echo "Usage: snapshot-delete <snapshot-name>"
          exit 1
        fi

        SNAPSHOT="$SNAPSHOT_DIR/persist-$1"

        if [ ! -d "$SNAPSHOT" ]; then
          echo "Error: Snapshot '$1' not found"
          exit 1
        fi

        echo "Deleting snapshot: $1"
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$SNAPSHOT"
        echo "Snapshot deleted"
      '';
    in
    {
      environment.systemPackages = [
        snapshotScript
        listSnapshotsScript
        rollbackScript
        deleteSnapshotScript
        pkgs.btrfs-progs
      ];

      # Auto-snapshot before nixos-rebuild
      system.activationScripts.preRebuildSnapshot = lib.stringAfter [ "specialfs" ] ''
        if [ -d /snapshots ] && [ -d /persist ]; then
          SNAP_NAME="pre-rebuild-$(date +%Y%m%d-%H%M%S)"
          ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r /persist /snapshots/persist-$SNAP_NAME || true
        fi
      '';
    };
}
