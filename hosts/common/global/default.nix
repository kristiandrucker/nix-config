# This file (and the global directory) holds config that is used on all hosts
{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./locale.nix
    ./nix.nix
    ./openssh.nix
    ./sops.nix
    ./tailscale.nix
    ./docker.nix
    ./node-exporter.nix
    ./auto-upgrade.nix
    ./firewall.nix
    ./domains.nix
    ./optin-persistence.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Configure home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  # Configure nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # Enable firmware with redistributable license
  hardware.enableRedistributableFirmware = true;

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  # Packages for all systems
  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_zen.perf

    # System utilities
    curl
    wget
    vim
    git
    htop
    btop
    tmux
    ripgrep
    fd
    jq
    yq

    # File utilities
    unzip
    zip
    gzip

    # Network utilities
    iptables
    dig
    tcpdump
    nmap

    # Monitoring tools
    lsof
    strace
    iotop
  ];
}
