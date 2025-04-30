{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  programs.zsh.enable = true;

  users.mutableUsers = false;
  users.users.kristian = {
    isNormalUser = true;
    # Use zsh as default shell
    shell = pkgs.zsh;
    extraGroups = ifTheyExist [
      "audio"
      "deluge"
      "docker"
      "git"
      "i2c"
      "libvirtd"
      "lxd"
      "mysql"
      "network"
      "networkmanager"
      "plugdev"
      "podman"
      "video"
      "wheel"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/kristian/ssh.pub);
    hashedPasswordFile = config.sops.secrets.kristian-password.path;
    packages = [pkgs.home-manager];
  };

  # Configure sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Setup SOPS secret for password
  sops.secrets.kristian-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  # Setup home-manager for the user
  home-manager.users.kristian = import ../../../../home/kristian/generic.nix;
}
