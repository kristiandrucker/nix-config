{
  config,
  pkgs,
  lib,
  ...
}: {
  services.audiobookshelf = {
    enable = true;
    # dataDir = "/persist/srv/audiobookshelf";
    port = 8800;
  };

  systemd.services.audiobookshelf.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = true;
    ProtectHome = true;
  };

  environment.persistence."/persist".directories = [
    "/var/lib/audiobookshelf"
    "/metadata"
  ];

  services.nginx.virtualHosts."books.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.audiobookshelf.port}";
      proxyWebsockets = true;
    };
  };
}
