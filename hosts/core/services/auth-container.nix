{
  config,
  pkgs,
  lib,
  ...
}: {
  # Configure SOPS secrets for the auth container
  sops.secrets."auth_container/admin_password" = {
    sopsFile = ../secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."auth_container/db_password" = {
    sopsFile = ../secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Define a Docker container for authentication service
  virtualisation.oci-containers.containers = {
    "auth" = {
      image = "nginx"; # This appears to be a custom authentication image
      autoStart = true;
      ports = [
        "127.0.0.1:8080:80" # Only expose locally
      ];
      environment = {
        # Environment variables for the auth container
        LOG_LEVEL = "info";
        ADMIN_USER = "admin";
        # Use passwordFiles for sensitive information
        ADMIN_PASSWORD_FILE = "/run/secrets/auth_container_admin_password";
        DB_PASSWORD_FILE = "/run/secrets/auth_container_db_password";
      };
      # Mount a persistent volume for data and secrets
      volumes = [
#        "/persist/var/lib/auth-data:/data"
        "${config.sops.secrets."auth_container/admin_password".path}:/run/secrets/auth_container_admin_password"
        "${config.sops.secrets."auth_container/db_password".path}:/run/secrets/auth_container_db_password"
      ];
    };
  };
  
  # Ensure the data directory exists with correct permissions
#  systemd.tmpfiles.rules = [
#    "d /persist/var/lib/auth-data 0750 root root - -"
#  ];

  # Expose through nginx proxy
  services.nginx.virtualHosts."auth.${config.domains.root}" = {
    enableACME = false;
    forceSSL = false;
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
    };
  };
}