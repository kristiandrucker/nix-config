{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."lidarr" = {
    owner = "lidarr";
    group = "lidarr";
    mode = "0400";
    #    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.lidarr = {
    enable = true;
    dataDir = "/persist/srv/lidarr";
    settings = {
      auth = {
        required = false;
      };
      postgres = {
        host = "pg.drkr.io";
        user = "lidarr";
        maindb = "lidarr-main";
        logdb = "lidarr-log";
      };
    };
    environmentFiles = [
      config.sops.secrets."lidarr".path
    ];
  };

  environment.persistence."/persist".directories = [
    "/srv/lidarr"
  ];

  services.nginx.virtualHosts."lidarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8686";
      proxyWebsockets = true;
    };
  };

  #  services.nginx.enable = lib.mkForce false;
  #  services.envoyProxy.enable = true;
  #  services.envoyProxy.virtualHosts."radarr.${config.domains.root}" = {
  #    port = 7878;
  ##    forceSSL = true;
  #    useACMEHost = "drkr.io";
  #  };
}
