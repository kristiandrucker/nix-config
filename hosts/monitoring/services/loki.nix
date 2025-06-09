{
  config,
  pkgs,
  ...
}: {
  # Enable Loki log aggregation service
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = 3100;
      };
      common = {
        path_prefix = config.services.loki.dataDir;
        storage.filesystem = {
          chunks_directory = "${config.services.loki.dataDir}/chunks";
          rules_directory = "${config.services.loki.dataDir}/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        ring.instance_addr = "127.0.0.1";
      };

      ingester.chunk_encoding = "snappy";

      limits_config = {
        retention_period = "120h";
        ingestion_burst_size_mb = 16;
        reject_old_samples = true;
        reject_old_samples_max_age = "12h";
      };

      table_manager = {
        retention_deletes_enabled = true;
        retention_period = "120h";
      };

      compactor = {
        retention_enabled = true;
        compaction_interval = "10m";
        working_directory = "${config.services.loki.dataDir}/compactor";
        delete_request_cancel_period = "10m"; # don't wait 24h before processing the delete_request
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };

      schema_config.configs = [
        {
          from = "2020-11-08";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index.prefix = "index_";
          index.period = "24h";
        }
      ];

      ruler = {
        storage = {
          type = "local";
          local.directory = "${config.services.loki.dataDir}/ruler";
        };
        rule_path = "${config.services.loki.dataDir}/rules";
        alertmanager_url = "http://alertmanager.r";
      };

      query_range.cache_results = true;
      limits_config.split_queries_by_interval = "24h";
    };
  };

  # Expose Loki via Nginx
  services.nginx.virtualHosts = {
    "loki.${config.domains.root}" = {
      forceSSL = true;
      useACMEHost = "drkr.io";
      locations."/" = {
        proxyPass = "http://localhost:3100";
        proxyWebsockets = true;
      };
    };
  };

  # Allow Tailscale nodes to access Loki
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [3100];

  # Ensure Loki data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/loki"
  ];
}
