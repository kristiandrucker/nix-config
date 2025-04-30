{
  config,
  pkgs,
  lib,
  ...
}: {
  services.cockpit.enable = true;
  #  services.cockpit.openFirewall = true;

  services.nginx.virtualHosts."*.ts.drkr.io" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.cockpit.port}";
      recommendedProxySettings = true;
    };
  };
}
