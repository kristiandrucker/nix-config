{
  inputs,
  lib,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports = [
    ../features/cli
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "kristian";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "24.11";
    sessionPath = ["$HOME/.local/bin"];

    persistence = {
      "/persist/${config.home.homeDirectory}" = {
        defaultDirectoryMethod = "symlink";
        directories = [
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Projects"
          ".local/bin"
          ".local/share/nix"
          ".local/share/zsh" # Add this line to persist ZSH history
          ".ssh"
          ".ssh/known_hosts.d"
        ];
        allowOther = true;
      };
    };
  };

  # Install additional packages for all users
  home.packages = with pkgs; [
    # Common utilities
    vim
    neovim
    git
    gnupg
    pinentry
    fastfetch
    pciutils

    # Archive utilities
    zip
    unzip
    gzip
    p7zip

    # Network utilities
    dig
    nmap
    netcat
    socat

    # System utilities
    htop
    lsof
    strace

    # Development tools
    gcc
    gnumake
    python3
  ];
}
