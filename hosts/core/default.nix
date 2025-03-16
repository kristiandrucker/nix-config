{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
#    ./services

#    ../common/global/openssh.nix
    ../common/users/kristian
#    ../common/optional/fail2ban.nix
#    ../common/optional/tailscale-exit-node.nix
  ];

  services.openssh.enable = true;

  networking = {
    hostName = "core";
    useDHCP = true;
  };
  system.stateVersion = "24.11";
}