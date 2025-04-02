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
    ../common/optional/fail2ban.nix
    ../common/optional/nginx.nix
    ../common/optional/blocky-dns.nix
    ../common/optional/ntp-server.nix
  ];

  networking = {
    hostName = "public-1";
    useDHCP = true;
  };

  system.stateVersion = "24.11";
}
