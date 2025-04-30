{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Overseerr service
  services.jellyseerr = {
    enable = true;
  };

  systemd.services.jellyseerr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = true;
    ProtectHome = true;
  };

  # Ensure the service directory exists and is persisted
  environment.persistence."/persist".directories = [
    "/var/lib/jellyseerr"
  ];

  # Nginx configuration for Overseerr
  services.nginx.virtualHosts."seer.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:5055";
      proxyWebsockets = true;
    };
  };
}
