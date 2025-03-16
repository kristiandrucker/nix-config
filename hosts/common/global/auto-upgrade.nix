{
  lib,
  ...
}: {
  # Enable automatic system upgrades
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    allowReboot = lib.mkDefault false;  # Be cautious about auto-reboots
    dates = lib.mkDefault "04:00";
    randomizedDelaySec = lib.mkDefault "45min";
  };
}