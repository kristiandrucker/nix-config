{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/kristian
  ];

  networking = {
    hostName = "dvr";
    useDHCP = true;
  };

  # Raspberry Pi specific configurations
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  
  # Bootloader for Raspberry Pi
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Use the latest kernel for better hardware compatibility
  boot.kernelPackages = pkgs.linuxPackages_latest;

  system.stateVersion = "24.11";
}