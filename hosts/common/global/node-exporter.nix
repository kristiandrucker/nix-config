{
  config,
  ...
}: {
  # Enable Prometheus Node Exporter
  services.prometheus.exporters.node = {
    enable = true;
    
    # Enable additional collectors
    enabledCollectors = [
      "systemd"
      "processes"
      "filesystem"
      "diskstats"
      "cpu"
      "meminfo"
      "netdev"
    ];
    
    # Add custom options to export more metrics
    extraFlags = [
      "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run|snap)($|/)"
      "--collector.netdev.device-exclude=^(lo|docker|veth).*"
    ];
  };
  
  # Open firewall for Node Exporter, but only on tailscale interface for security
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [config.services.prometheus.exporters.node.port];
  };
}