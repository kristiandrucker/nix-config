{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."radarr" = {
    owner = "radarr";
    group = "radarr";
    mode = "0400";
    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.radarr = {
    enable = true;
    dataDir = "/persist/srv/radarr";
    settings = {
      auth = {
        required = false;
      };
      postgres = {
        host = "pg.drkr.io";
        user = "radarr";
        maindb = "radarr-main";
        logdb = "radarr-log";
      };
    };
    environmentFiles = [
      config.sops.secrets."radarr".path
    ];
  };

  environment.persistence."/persist".directories = [
    "/srv/radarr"
  ];

  services.nginx.virtualHosts."radarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:7878";
      proxyWebsockets = true;
    };
  };
}
