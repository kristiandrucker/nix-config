{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
#    ./services

#    ../common/global
    ../common/users/kristian
#    ../common/optional/fail2ban.nix
#    ../common/optional/tailscale-exit-node.nix
  ];

  networking = {
    hostName = "core.drkr.io";
    useDHCP = true;
  };
  system.stateVersion = "24.11";
}