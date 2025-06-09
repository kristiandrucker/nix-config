{
  config,
  pkgs,
  lib,
  ...
}: {
  services.komga = {
    enable = true;
    stateDir = "/persist/srv/komga";
    settings.server.port = 8231;
  };

  environment.persistence."/persist".directories = [
    "/srv/komga"
  ];

  services.nginx.virtualHosts."ebooks.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.komga.settings.server.port}";
      proxyWebsockets = true;
    };
  };
}
