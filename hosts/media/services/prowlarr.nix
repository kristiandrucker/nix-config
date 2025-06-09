{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define the database password secret
  sops.secrets."prowlarr" = {
    #    owner = "prowlarr";
    #    group = "prowlarr";
    mode = "0400";
    format = "yaml";
    sopsFile = ../secrets.yaml;
  };

  services.prowlarr = {
    enable = true;
    settings = {
      auth = {
        required = false;
      };
      postgres = {
        host = "pg.drkr.io";
        user = "prowlarr";
        maindb = "prowlarr-main";
        logdb = "prowlarr-log";
      };
    };
    environmentFiles = [
      config.sops.secrets."radarr".path
    ];
  };

  environment.persistence."/persist".directories = [
      "/var/lib/prowlarr"
    ];

  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = true;
    ProtectHome = true;
  };

  services.nginx.virtualHosts."prowlarr.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:9696";
      proxyWebsockets = true;
    };
  };
}
