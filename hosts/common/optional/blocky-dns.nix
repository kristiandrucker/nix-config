{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Blocky DNS service
  virtualisation.oci-containers.containers = {
    blocky = {
      image = "spx01/blocky:latest";
      autoStart = true;
      ports = [
        "53:53/tcp"   # DNS over TCP
        "53:53/udp"   # DNS over UDP
        "4000:4000"   # Admin interface
        "443:443"     # DNS over HTTPS
        "853:853"     # DNS over TLS
      ];
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [
        "/persist/var/lib/blocky:/app/config"
      ];
      extraOptions = [
        "--restart=unless-stopped"
      ];
    };
  };

  # Ensure config directory exists
  systemd.tmpfiles.rules = [
    "d /persist/var/lib/blocky 0750 root root - -"
  ];

  # Create basic configuration file for Blocky if it doesn't exist
  system.activationScripts.blockyConfig = ''
    if [ ! -f /persist/var/lib/blocky/config.yml ]; then
      mkdir -p /persist/var/lib/blocky
      cat > /persist/var/lib/blocky/config.yml << 'EOF'
upstream:
  default:
    - 1.1.1.1
    - 8.8.8.8
    - 9.9.9.9
blocking:
  blackLists:
    ads:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  clientGroupsBlock:
    default:
      - ads
  refreshPeriod: 4h
ports:
  dns: 53
  http: 4000
  https: 443
  tls: 853
prometheus:
  enable: true
  path: /metrics
bootstrapDns:
  - 1.1.1.1
certFile: /app/config/cert.pem
keyFile: /app/config/key.pem
EOF
    fi
  '';

  # Open the necessary firewall ports
  networking.firewall = {
    allowedTCPPorts = [ 
      53    # DNS
      443   # DNS over HTTPS
      853   # DNS over TLS
      4000  # Admin interface
    ];
    allowedUDPPorts = [ 
      53    # DNS
    ];
  };
}