{
  config,
  lib,
  pkgs,
  ...
}: {
  # Define the secret for the borgbackup passphrase
  sops.secrets."borgbackup_passphrase" = {
    sopsFile = ../secrets.yaml;
  };

  # Mount the NFS share
  fileSystems."/mnt/backup" = {
    device = "10.1.0.32:/var/nfs/shared/Backups";
    fsType = "nfs";
    options = ["noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"];
  };

  # Ensure the mount directory exists
  system.activationScripts.createBackupMountPoint = ''
    mkdir -p /mnt/backup
  '';

  # Create a directory for this host
  system.activationScripts.createHostBackupDir = ''
    # Only try to create the directory if the mount point exists and is accessible
    if mountpoint -q /mnt/backup 2>/dev/null || [ -w /mnt/backup ]; then
      mkdir -p /mnt/backup/${config.networking.hostName}
    else
      echo "Warning: Backup mount point not available, skipping directory creation"
    fi
  '';

  services.borgbackup.jobs = {
    system-backup = {
      paths = [
        "/persist"
        "/etc"
        "/var/lib"
      ];
      exclude = [
        "/var/lib/docker"
        "*.temp"
        "*/temp/*"
      ];
      repo = "/mnt/backup/${config.networking.hostName}";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets."borgbackup_passphrase".path}";
      };
      compression = "auto,zstd";
      startAt = "hourly";
      prune.keep = {
        hourly = 12;
        daily = 7;
        weekly = 4;
        monthly = 6;
      };

      # Mount the NFS share before backup and unmount after
      preHook = ''
        # Create host backup directory if it doesn't exist
        mkdir -p /mnt/backup/${config.networking.hostName}

        # Initialize repository if it doesn't exist or has no manifest
        if [ ! -d "/mnt/backup/${config.networking.hostName}/data" ] || ! borg info /mnt/backup/${config.networking.hostName} >/dev/null 2>&1; then
          echo "Initializing repository at /mnt/backup/${config.networking.hostName}"
          export BORG_PASSPHRASE="$(cat ${config.sops.secrets."borgbackup_passphrase".path})"
          borg init --encryption=repokey-blake2 /mnt/backup/${config.networking.hostName} || true
        fi
      '';

      postHook = ''
        # Keep the mount active for a while via systemd automount
        if [ -d "/mnt/backup/${config.networking.hostName}" ]; then
          touch /mnt/backup/${config.networking.hostName}/.backup-completed || true
        else
          echo "Warning: Backup directory not available, skipping touch operation"
        fi
      '';
    };
  };
}
