{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
#    ./services

    ../common/global
    ../common/users/kristian
    ../common/optional/fail2ban.nix
    ../common/optional/nginx.nix
  ];

  networking = {
    hostName = "media";
    useDHCP = true;
  };

  # Enable NVIDIA drivers for Quadro P400
#  services.xserver.videoDrivers = [ "nvidia" ];
#  hardware.nvidia = {
#    package = config.boot.kernelPackages.nvidiaPackages.stable;
#    modesetting.enable = true;
#    powerManagement.enable = true;
#    open = false;
#    nvidiaSettings = true;
#  };
  
  # Enable hardware acceleration for the GPU
#  hardware.opengl = {
#    enable = true;
#    driSupport = true;
#    driSupport32Bit = true;
#  };

  system.stateVersion = "24.11";
}