{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/kristian
    ../common/optional/acme.nix
    ../common/optional/fail2ban.nix
    ../common/optional/nginx.nix
    ../common/optional/proxmox.nix
  ];

  networking = {
    hostName = "core";
    useDHCP = true;
  };

  system.stateVersion = "24.11";
}