{
  config,
  pkgs,
  lib,
  ...
}: {
  virtualisation.oci-containers.containers."pgvector" = {
    image = "pgvector/pgvector:pg17";
    autoStart = true;
    ports = [
      "0.0.0.0:5432:5432"
    ];
    environment = {
      POSTGRES_PASSWORD = "postgres";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/persist/mnt/data/pgvector:/usr/local/var/postgres"
    ];
  };

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [5432];

  services.n8n = {
    enable = true;
    webhookUrl = "https://n8n-hook.drkr.io";
    # settings = {
    #   n8n = {
    #     log = {
    #       level = "debug";
    #     };
    #   };
    # };
  };

  systemd.services.n8n.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = lib.mkForce true;
    ProtectHome = lib.mkForce true;
  };

  environment.persistence."/persist".directories = [
    "/var/lib/n8n"
    "/mnt/data/pgvector"
  ];

  services.nginx.virtualHosts."n8n.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:5678";
      proxyWebsockets = true;
    };
  };
}
