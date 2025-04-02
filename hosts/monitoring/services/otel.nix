{
  config,
  pkgs,
  ...
}: {
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {};
            http = {};
          };
        };
        syslog = {
          udp = {
            listen_address = "0.0.0.0:5514";
          };
          protocol = "rfc3164";
          location = "Europe/Berlin";
        };
        #        netflow = {
        #          endpoint = "0.0.0.0:2055";
        #        };
      };

      processors = {
        batch = {};
      };

      exporters = {
        otlp = {
          endpoint = "http://localhost:4316";
          tls.insecure = true;
        };
        prometheusremotewrite = {
          endpoint = "http://localhost:9090/api/v1/push";
          tls.insecure = true;
        };
        "otlphttp/loki" = {
          endpoint = "http://localhost:3100/otlp";
        };
      };

      service = {
        pipelines = {
          traces = {
            receivers = ["otlp"];
            processors = ["batch"];
            exporters = ["otlp"];
          };
          metrics = {
            receivers = ["otlp"];
            processors = ["batch"];
            exporters = ["prometheusremotewrite"];
          };
          logs = {
            receivers = ["otlp" "syslog"];
            processors = ["batch"];
            exporters = ["otlphttp/loki"];
          };
        };
      };
    };
  };

  # Allow Tailscale nodes to access Loki
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [2055 4317 4318];
  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [5514];
  networking.firewall.interfaces."ens18".allowedUDPPorts = [5514];
}
