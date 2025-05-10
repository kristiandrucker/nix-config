{
  config,
  lib,
  pkgs,
  ...
}: {
  services.home-assistant = {
    enable = true;
    config = {};
  };

  services.nginx.virtualHosts."ha.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/".extraConfig = ''
      proxy_pass http://localhost:${toString config.services.home-assistant.config.http.server_port};
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    '';
  };

  environment.persistence."/persist".directories = [
    "/var/lib/hass"
  ];
}
