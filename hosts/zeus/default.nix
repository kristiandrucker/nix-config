{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./cpu-power.nix
    ./nixvirt.nix
    ./services
    ../builder/services/pixiecore.nix

    # Import NixVirt module
    inputs.NixVirt.nixosModules.default

    "${inputs.hardware}/common/cpu/amd"
    "${inputs.hardware}/common/gpu/nvidia/pascal"
    "${inputs.hardware}/common/pc/ssd"

    ../common/global
    ../common/users/kristian
    ../common/optional/media-mount.nix
    ../common/optional/nvidia.nix
    ../common/optional/fail2ban.nix
    ../common/optional/cockpit.nix
  ];

  networking = {
    hostName = "zeus";
    useDHCP = false; # Set to false when configuring specific interfaces
    useNetworkd = true; # Use systemd-networkd for better bridge support
  };

  system.stateVersion = "24.11";
}
