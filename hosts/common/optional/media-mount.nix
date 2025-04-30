{
  fileSystems."/mnt/media" = {
    device = "10.1.0.32:/var/nfs/shared/Media";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" "nconnect=8"];
  };

  boot.supportedFilesystems = ["nfs"];
}
