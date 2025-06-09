{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."readarr" = {
    owner = "readarr";
    group = "readarr";
    mode = "0400";
    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.readarr = {
    enable = true;
    dataDir = "/persist/srv/readarr";
    settings = {
      auth = {
        required = false;
      };
      postgres = {
        host = "pg.drkr.io";
        user = "readarr";
        maindb = "readarr-main";
        logdb = "readarr-log";
        cachedb = "readarr-cache";
      };
    };
    environmentFiles = [
      config.sops.secrets."readarr".path
    ];
  };

  environment.persistence."/persist".directories = [
    "/srv/readarr"
  ];

  services.nginx.virtualHosts."readarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8787";
      proxyWebsockets = true;
    };
  };
}
