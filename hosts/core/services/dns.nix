{
  config,
  pkgs,
  ...
}: {
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 53;
        http = "127.0.0.1:4000";
      };
      prometheus.enable = true;
      queryLog = {
        type = "console";
      };
      upstreams.timeout = "10s";
      upstreams.groups.default = [
        "https://dns.quad9.net/dns-query"
      ];
      bootstrapDns = [
        {
          upstream = "https://dns.quad9.net/dns-query";
          ips = ["9.9.9.9" "149.112.112.112"];
        }
      ];
      # Reverse lookup (does this even work?)
      clientLookup = {
        upstream = "10.1.1.1";
      };
      # My custom entries for local network
      customDNS = {
        customTTL = "1h";
        mapping = {};
      };
      conditional = {};
      blocking = {
        blockType = "zeroIP";
        denylists = {
          ads = [
            "https://adaway.org/hosts.txt"
            "https://v.firebog.net/hosts/AdguardDNS.txt"
            "https://v.firebog.net/hosts/Admiral.txt"
            "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://v.firebog.net/hosts/Easylist.txt"
            "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
            "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
          ];
          telemetry = [
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
            "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
          ];
        };
        allowlists = {};
      };
    };
  };

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];

  services.nginx.virtualHosts."dns.${config.domains.root}" = {
    forceSSL = true;
    useACMEHost = "drkr.io";
    locations."/" = {
      proxyPass = "http://localhost:4000";
      proxyWebsockets = true;
    };
  };
}
