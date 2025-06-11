{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_zen;
  # Enable firmware with redistributable license
  hardware.enableRedistributableFirmware = true;

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
