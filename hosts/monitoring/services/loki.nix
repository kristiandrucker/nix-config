{
  config,
  pkgs,
  ...
}: {
  # Enable Loki log aggregation service
  services.loki = {
    enable = false;
    configuration = {
      auth_enabled = false;
      
      server = {
        http_listen_port = 3100;
      };
      
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      
      schema_config = {
        configs = [
          {
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
          shared_store = "filesystem";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      limits_config = {
        enforce_metric_name = false;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };
      
      chunk_store_config = {
        max_look_back_period = "0s";
      };
      
      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      
      compactor = {
        working_directory = "/var/lib/loki";
        shared_store = "filesystem";
      };
    };
  };
  
  # Expose Loki via Nginx
  services.nginx.virtualHosts = {
    "loki.${config.domains.root}" = {
      enableACME = false;
      forceSSL = false;
      locations."/" = {
        proxyPass = "http://localhost:3100";
        proxyWebsockets = true;
      };
    };
  };
  
  # Allow Tailscale nodes to access Loki
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 3100 ];
  
  # Ensure Loki data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/loki"
  ];
}