{
  config,
  lib,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    enableTCPIP = true;

    ensureDatabases = [
      "sonarr-main"
      "sonarr-log"
      "radarr-main"
      "radarr-log"
      "lidarr-main"
      "lidarr-log"
      "prowlarr-main"
      "prowlarr-log"
      "mastodon"
      #      "overseerr"
    ];

    ensureUsers = [
      {name = "sonarr";}
      {name = "radarr";}
      {name = "lidarr";}
      {name = "prowlarr";}
      {name = "mastodon";}
      # { name = "overseerr"; }
    ];

    settings = {
      # https://pgtune.leopard.in.ua/?dbVersion=17&osType=linux&dbType=mixed&cpuNum=6&totalMemory=32&totalMemoryUnit=GB&connectionNum=200&hdType=ssd
      # DB Version: 17
      # OS Type: linux
      # DB Type: mixed
      # Total Memory (RAM): 32 GB
      # CPUs num: 6
      # Connections num: 200
      # Data Storage: ssd

      max_connections = 200;
      shared_buffers = "8GB";
      effective_cache_size = "24GB";
      maintenance_work_mem = "2GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "6990kB";
      huge_pages = "try";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 6;
      max_parallel_workers_per_gather = 3;
      max_parallel_workers = 6;
      max_parallel_maintenance_workers = 3;
    };

    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      host  all      all     100.0.0.0/8         trust
      host  all      all     fd7a:115c:a1e0::/48 trust
      host  all      all     10.0.0.0/8          trust
    '';
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [config.services.postgresql.settings.port];
  };

  environment.persistence."/persist".directories = [
    config.services.postgresql.dataDir
  ];
}
