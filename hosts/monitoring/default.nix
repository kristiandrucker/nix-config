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
    ../common/optional/fail2ban.nix
    ../common/optional/nginx.nix
  ];

  networking = {
    hostName = "monitoring";
    useDHCP = true;
  };

  system.stateVersion = "24.11";
}