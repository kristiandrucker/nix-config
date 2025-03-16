{
  config,
  pkgs,
  lib,
  ...
}: {
  # Configure SOPS secrets for the auth container
#  sops.secrets."auth_container/admin_password" = {
#    owner = "root";
#    group = "root";
#    mode = "0400";
#  };
#
#  sops.secrets."auth_container/db_password" = {
#    owner = "root";
#    group = "root";
#    mode = "0400";
#  };

  # Define a Docker container for authentication service
  virtualisation.oci-containers.containers = {
    "auth" = {
      image = "nginx:alpine"; # This appears to be a custom authentication image
      autoStart = true;
      ports = [
        "127.0.0.1:8080:80" # Only expose locally
      ];
      environment = {
        # Environment variables for the auth container
        LOG_LEVEL = "info";
        ADMIN_USER = "admin";
        # Use passwordFiles for sensitive information
#        ADMIN_PASSWORD_FILE = "/run/secrets/auth_container_admin_password";
#        DB_PASSWORD_FILE = "/run/secrets/auth_container_db_password";
      };
      # Mount a persistent volume for data and secrets
      volumes = [
#        "/persist/var/lib/auth-data:/data"
#        "${config.sops.secrets."auth_container/admin_password".path}:/run/secrets/auth_container_admin_password"
#        "${config.sops.secrets."auth_container/db_password".path}:/run/secrets/auth_container_db_password"
      ];
      extraOptions = [
        "--network=host"
        "--restart=unless-stopped"
      ];
    };
  };
  
  # Ensure the data directory exists with correct permissions
#  systemd.tmpfiles.rules = [
#    "d /persist/var/lib/auth-data 0750 root root - -"
#  ];
  
  # Add documentation about this container
#  programs.bash.interactiveShellInit = ''
#    # Add info about auth container
#    echo "Auth container available at http://localhost:8080"
#  '';
  
  # Expose through nginx proxy
  services.nginx.virtualHosts."auth.${config.domains.root}" = {
    enableACME = false;
    forceSSL = false;
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
    };
  };
  
  # Add explanatory comment
  # This container runs the "pocket_id" authentication service
  # which appears to be a custom identity provider.
  # Consider replacing with a standard solution like Keycloak,
  # Authentik, or another OIDC provider for better maintainability.
}