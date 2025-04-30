{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."sonarr" = {
    owner = "sonarr";
    group = "sonarr";
    mode = "0400";
    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.sonarr = {
    enable = true;
    dataDir = "/persist/srv/sonarr";
    settings = {
      auth = {
        required = false;
      };
      postgres = {
        host = "pg.drkr.io";
        user = "sonarr";
        maindb = "sonarr-main";
        logdb = "sonarr-log";
      };
    };
    environmentFiles = [
      config.sops.secrets."sonarr".path
    ];
  };

  environment.persistence."/persist".directories = [
    "/srv/sonarr"
  ];

  services.nginx.virtualHosts."sonarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8989";
      proxyWebsockets = true;
    };
  };
}
