{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define a Docker container for authentication service
  virtualisation.oci-containers.containers = {
    "auth" = {
      image = "ghcr.io/pocket-id/pocket-id:v0.43.1"; # This appears to be a custom authentication image
      autoStart = true;
      ports = [
        "127.0.0.1:8000:8000" # Only expose locally
      ];
      environment = {
        PUBLIC_APP_URL = https://auth.drkr.io;
        TRUST_PROXY = "true";
        CADDY_PORT = "8000";
      };
      # Mount a persistent volume for data and secrets
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/persist/mnt/data/auth/data:/app/backend/data"
      ];
    };
  };

  # Persist container data
  environment.persistence."/persist".directories = [
    "/mnt/data/auth/data"
  ];

  # Expose through nginx proxy
  services.nginx.virtualHosts."auth.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8000";
      proxyWebsockets = true;
    };
  };
}