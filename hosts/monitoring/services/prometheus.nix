{
  config,
  lib,
  outputs,
  pkgs,
  ...
}: 
let
  # Get a list of hostnames from nixos configurations
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  
  # Alert rules file
  alertRules = pkgs.writeText "prometheus-alert-rules.yml" ''
    groups:
    - name: basic-alerts
      rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 5 minutes."
      
      - alert: HighCPULoad
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High CPU load on {{ $labels.instance }}"
          description: "CPU load is above 90% for more than 15 minutes."
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 90% for more than 15 minutes."
      
      - alert: HighDiskUsage
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"}) > 90
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High disk usage on {{ $labels.instance }}"
          description: "Disk usage is above 90% for more than 15 minutes."
  '';
  
  # Alertmanager configuration file
  alertmanagerConfig = pkgs.writeText "alertmanager.yml" ''
    global:
      resolve_timeout: 5m
      
    route:
      group_by: ['alertname', 'job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      receiver: 'email'
      
    receivers:
    - name: 'email'
      email_configs:
      - to: 'admin@${config.domains.root}'
        from: 'alertmanager@monitoring.${config.domains.root}'
        smarthost: 'smtp.${config.domains.root}:587'
        auth_username: 'alertmanager@${config.domains.root}'
        auth_identity: 'alertmanager@${config.domains.root}'
        auth_password: '${config.sops.secrets.smtp-password.path}'
        
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'instance']
  '';
in
{
  # Add SOPS secret for SMTP password
  sops.secrets."grafana/smtp_password" = {
    sopsFile = ../secrets.yaml;
  };

  # Prometheus server configuration
  services.prometheus = {
    enable = true;
    
    # Retain 15 days of metrics
    retentionTime = "15d";
    
    # Configure global scrape settings
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    
    scrapeConfigs = [
      # Scrape Prometheus itself
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.port}" ];
          labels = {
            instance = "monitoring";
          };
        }];
      }
      
      # Scrape node_exporter metrics from all nodes via Tailscale
      {
        job_name = "node";
        static_configs = builtins.map (host: {
          targets = [ "${host}.ts.${config.domains.root}:9100" ];
          labels = {
            instance = host;
          };
        }) nixosConfigs;
      }
      
      # Scrape Hydra metrics
      {
        job_name = "hydra";
        static_configs = [{
          labels = {
            instance = "hydra";
          };
          targets = [
            "builder.ts.${config.domains.root}:9198"
            "builder.ts.${config.domains.root}:9199"
          ];
        }];
      }
    ];
    
    # Configure alerting rules using external file
    alertmanagers = [{
      scheme = "http";
      path_prefix = "/";
      static_configs = [{
        targets = [ "localhost:9093" ];
      }];
    }];
    
    # Use external rules file
    ruleFiles = [ alertRules ];
  };
  
  # Configure AlertManager with external config
  services.prometheus.alertmanager = {
#    enable = true;
#    configFile = alertmanagerConfig;
  };
  
  # Expose Prometheus via Nginx
  services.nginx.virtualHosts = {
    "prometheus.${config.domains.root}" = {
#      enableACME = false;
#      forceSSL = false;
#      basicAuthFile = config.sops.secrets.prometheus-htpasswd.path;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.prometheus.port}";
        proxyWebsockets = true;
      };
    };
    
    "alertmanager.${config.domains.root}" = {
#      enableACME = false;
#      forceSSL = false;
#      basicAuthFile = config.sops.secrets.alertmanager-htpasswd.path;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.prometheus.alertmanager.port}";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9090 3000 ];
  
  # Add secrets for HTTP basic auth
  sops.secrets.prometheus-htpasswd = {
    sopsFile = ../secrets.yaml;
  };
  
  sops.secrets.alertmanager-htpasswd = {
    sopsFile = ../secrets.yaml;
  };
  
  # Ensure Prometheus data persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/prometheus2"
    "/var/lib/alertmanager"
  ];
}