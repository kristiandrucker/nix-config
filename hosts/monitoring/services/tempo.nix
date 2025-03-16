{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Tempo distributed tracing
  services.tempo = {
    enable = false;
    settings = {
      server = {
        http_listen_port = 3200;
      };
      
      distributor = {
        receivers = {
          jaeger = {
            protocols = {
              thrift_http = {
                endpoint = "0.0.0.0:14268";
              };
            };
          };
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317";
              };
              http = {
                endpoint = "0.0.0.0:4318";
              };
            };
          };
        };
      };
      
      ingester = {
        trace_idle_period = "10s";
        max_block_bytes = 1000000;
        max_block_duration = "5m";
      };
      
      compactor = {
        compaction = {
          compaction_window = "1h";
          max_block_bytes = 100000000;
          block_retention = "48h";
          compacted_block_retention = "10m";
        };
      };
      
      storage = {
        trace = {
          backend = "local";
          block = {
            bloom_filter_false_positive = 0.05;
            index_downsample_bytes = 1000;
            encoding = "zstd";
          };
          wal = {
            path = "/var/lib/tempo/wal";
          };
          local = {
            path = "/var/lib/tempo/blocks";
          };
          pool = {
            max_workers = 100;
            queue_depth = 10000;
          };
        };
      };
    };
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
    3200   # Tempo HTTP
    4317   # OTLP gRPC
    4318   # OTLP HTTP
    14268  # Jaeger HTTP
  ];
  
  # Ensure Tempo data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/tempo"
  ];
}