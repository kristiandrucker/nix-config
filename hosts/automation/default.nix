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
    ../common/optional/nginx.nix
    ../common/optional/fail2ban.nix
    ../common/optional/proxmox.nix
  ];

  networking = {
    hostName = "automation";
    useDHCP = true;
  };

  system.stateVersion = "25.05";
}
