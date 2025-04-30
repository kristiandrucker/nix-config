{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the VPN credentials secret
  sops.secrets."qbittorrent/vpn_credentials" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Set up Wireguard VPN
  networking.wg-quick.interfaces = {
    wg-qbittorrent = {
      # This will be populated from the SOPS secret
      configFile = config.sops.secrets."qbittorrent/vpn_credentials".path;
    };
  };

  # Enable qBittorrent service
  services.qbittorrent = {
    enable = true;
    dataDir = "/persist/srv/qbittorrent";
    openFirewall = true;
    port = 8080;
    user = "qbittorrent";
    group = "qbittorrent";
  };

  # Create qbittorrent user and group
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "qbittorrent";
    home = "/var/lib/qbittorrent";
    createHome = true;
  };
  users.groups.qbittorrent = {};

  # Ensure qBittorrent only uses the VPN connection
  systemd.services.qbittorrent = {
    after = ["wg-quick-wg-qbittorrent.service"];
    requires = ["wg-quick-wg-qbittorrent.service"];
    serviceConfig = {
      # Use network namespace to isolate qBittorrent
      NetworkNamespacePath = "/run/netns/qbittorrent-vpn";
    };
  };

  # Create network namespace for qBittorrent
  systemd.services.qbittorrent-vpn-netns = {
    description = "Create network namespace for qBittorrent VPN";
    before = ["wg-quick-wg-qbittorrent.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add qbittorrent-vpn";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del qbittorrent-vpn";
    };
    wantedBy = ["multi-user.target"];
  };

  # Modify wg-quick service to use the network namespace
  systemd.services."wg-quick-wg-qbittorrent" = {
    after = ["qbittorrent-vpn-netns.service"];
    requires = ["qbittorrent-vpn-netns.service"];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/qbittorrent-vpn";
    };
  };

  # Persistence for qBittorrent data
  environment.persistence."/persist".directories = [
    "/srv/qbittorrent"
  ];

  # Nginx configuration for qBittorrent
  services.nginx.virtualHosts."qb.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
    };
  };
}
