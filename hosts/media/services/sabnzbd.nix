{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable SABnzbd service
  services.sabnzbd = {
    enable = true;
    # Store data in a persistent location
    configFile = "/persist/srv/sabnzbd/sabnzbd.ini";
  };

  # Ensure the service directory exists and is persisted
  environment.persistence."/persist".directories = [
    "/srv/sabnzbd"
  ];

  # Create required directories
  system.activationScripts.sabnzbd-dirs = ''
    mkdir -p /persist/srv/sabnzbd
    chown sabnzbd:sabnzbd /persist/srv/sabnzbd
  '';

  # Nginx configuration for SABnzbd
  services.nginx.virtualHosts."sab.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
    };
  };
}
