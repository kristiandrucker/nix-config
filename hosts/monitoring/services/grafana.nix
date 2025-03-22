{
  config,
  pkgs,
  ...
}: {
  # Enable Grafana service
  services.grafana = {
    enable = true;
    
    # Server settings
    settings = {
      server = {
        domain = "grafana.${config.domains.root}";
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      
      security = {
        admin_user = "admin";
        admin_password = "admin";
      };
      
      # Automatically add our data sources
      analytics.reporting_enabled = false;
      
#      auth.anonymous = {
#        enabled = false;
#      };
    };
    
    # Configure data sources
    provision = {
      enable = true;
      
      # Add our data sources
      datasources.settings.datasources = [
        {
          name = "prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
        }
        {
          name = "Tempo";
          type = "tempo";
          url = "http://localhost:3200";
        }
      ];
      
      # Add default dashboards
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Default";
            options.path = "${pkgs.grafana-dashboards}/dashboards";
            orgId = 1;
            type = "file";
            disableDeletion = true;
            updateIntervalSeconds = 60;
          }
          {
            name = "Node Exporter";
            options.path = "${pkgs.grafana}/share/grafana/public/dashboards";
            orgId = 1;
            type = "file";
            disableDeletion = true;
            updateIntervalSeconds = 60;
          }
        ];
      };
    };
  };
  
  # Create grafana-dashboards package with built-in dashboards
  nixpkgs.overlays = [
    (self: super: {
      grafana-dashboards = pkgs.runCommand "grafana-dashboards" {} ''
        mkdir -p $out/dashboards
        cp ${./dashboards/node-exporter.json} $out/dashboards/node-exporter.json
        cp ${./dashboards/grafana-tailscale.json} $out/dashboards/grafana-tailscale.json
      '';
    })
  ];
  
  # Expose Grafana via Nginx
  services.nginx.virtualHosts = {
    "grafana.${config.domains.root}" = {
      enableACME = false;
      forceSSL = false;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };
  };
  
  # Add secret for Grafana admin password
  sops.secrets."grafana/admin_password" = {
    sopsFile = ../secrets.yaml;
  };
  
  # Ensure Grafana data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/grafana"
  ];
}