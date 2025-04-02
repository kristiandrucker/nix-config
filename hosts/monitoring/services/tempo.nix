{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Tempo distributed tracing
  services.tempo = {
    enable = true;
    settings = {
      server = {
        http_listen_port = 3200;
        grpc_listen_port = 9096;
      };

      distributor = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4316";
              };
            };
          };
        };
      };

      storage.trace = {
        backend = "local";
        wal.path = "/var/lib/tempo/wal";
        local.path = "/var/lib/tempo/blocks";
      };
      usage_report.reporting_enabled = false;
    };
  };

  systemd.services.tempo.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateTmp = true;
    ProtectHome = true;
  };

  # Expose Tempo via Nginx
  services.nginx.virtualHosts = {
    "tempo.${config.domains.root}" = {
      enableACME = false;
      forceSSL = false;
      locations."/" = {
        proxyPass = "http://localhost:3200";
        proxyWebsockets = true;
      };
    };
  };

  # Allow Tailscale nodes to access Tempo
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    3200 # Tempo HTTP
    #4317   # OTLP gRPC
    #4318   # OTLP HTTP
    14268 # Jaeger HTTP
  ];

  # Ensure Tempo data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/tempo"
    #    "/var/lib/tempo2"
  ];
}
