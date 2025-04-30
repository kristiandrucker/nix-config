{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  services.plex = {
    enable = true;
    dataDir = "/persist/srv/plex";
    openFirewall = true;
  };

  systemd.services.plex.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = true;
    ProtectHome = true;
    #    User=lib.mkForce "root";
    #    Group=lib.mkForce "root";
  };

  environment.persistence."/persist".directories = [
    "/srv/plex"
  ];

  services.nginx.virtualHosts."plex.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:32400";
      proxyWebsockets = true;
    };
  };
}
