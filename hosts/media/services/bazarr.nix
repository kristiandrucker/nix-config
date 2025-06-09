{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."bazarr" = {
    owner = "bazarr";
    group = "bazarr";
    mode = "0400";
    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.bazarr = {
    enable = true;
    dataDir = "/persist/srv/bazarr";
    #    settings = {
    #      postgres = {
    #        host = "pg.drkr.io";
    #        user = "bazarr";
    #        maindb = "bazarr-main";
    #        logdb = "bazarr-log";
    #      };
    #    };
    #    environmentFiles = [
    #      config.sops.secrets."bazarr".path
    #    ];
  };

  environment.persistence."/persist".directories = [
    "/srv/bazarr"
  ];

  services.nginx.virtualHosts."bazarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:6767";
      proxyWebsockets = true;
    };
  };
}
