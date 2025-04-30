{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/kristian
    ../common/optional/acme.nix
    ../common/optional/fail2ban.nix
    ../common/optional/npm.nix
    ../common/optional/nginx.nix
    ../common/optional/proxmox.nix
  ];

  networking = {
    hostName = "core";
    useDHCP = true;
  };

  boot.kernelParams = ["console=ttyS0,115200n8" "console=tty0"];

  system.stateVersion = "25.05";
}
