{config, ...}: {
  services.nginx.virtualHosts = {
    "dl.${config.domains.root}" = {
      forceSSL = true;
      enableACME = true;
      locations."/".root = "/srv/files";
    };
  };
}
