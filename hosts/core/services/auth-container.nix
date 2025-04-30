{
  config,
  pkgs,
  lib,
  ...
}: {
  services.pocket-id = {
    enable = true;
    settings = {
      PUBLIC_APP_URL = "https://auth.drkr.io";
      INTERNAL_BACKEND_URL = "http://localhost:8882";
      TRUST_PROXY = true;
      PORT = "8881";
      BACKEND_PORT = "8882";
    };
  };

  # Persist container data
  environment.persistence."/persist".directories = [
    "/var/lib/pocket-id"
  ];

  # Expose through nginx proxy
  services.nginx.virtualHosts."auth.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8881";
      recommendedProxySettings = true;
    };
    locations."/api" = {
      proxyPass = "http://localhost:8882";
      recommendedProxySettings = true;
    };
    locations."/.well-known" = {
      proxyPass = "http://localhost:8882";
      recommendedProxySettings = true;
    };
  };
}
