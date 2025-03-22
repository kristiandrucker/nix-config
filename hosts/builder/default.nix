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
    ../common/optional/acme.nix
    ../common/optional/fail2ban.nix
    ../common/optional/nginx.nix
  ];

  networking = {
    hostName = "builder";
    useDHCP = true;
  };

  # Increase max builders for better performance
  nix.settings = {
    max-jobs = lib.mkDefault 8;
    cores = lib.mkDefault 0;
    trusted-users = ["hydra" "hydra-evaluator" "hydra-queue-runner"];
  };
  
  # Additional packages for build environment
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    cmake
    pkg-config
    git
    direnv
  ];

  system.stateVersion = "24.11";
}