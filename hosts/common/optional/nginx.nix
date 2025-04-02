{config, ...}: {
  # Enable nginx with recommended settings
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
  };

  # Open firewall ports for HTTP/HTTPS
  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];
}
