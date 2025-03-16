{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./machines.nix
  ];

  # Enable Hydra service
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.${config.domains.root}";
    notificationSender = "hydra@${config.domains.root}";
    port = 3000;
    buildMachinesFiles = [];
    useSubstitutes = true;
    logo = null;
    
    # Configure Hydra with GitHub integration
    extraConfig = ''
      <githubstatus>
        jobs = .*
        useShortContext = true
      </githubstatus>
      
      <trace>
        postgresql-uri = dbi:Pg:dbname=hydra;user=hydra;
        queue-runner-count = 1
        gc-roots-dir = /nix/var/nix/gcroots/hydra
      </trace>
      
      <hydra_notify>
        <prometheus>
          listen_address = 127.0.0.1
          port = 9199
        </prometheus>
      </hydra_notify>
    '';
  };

  # Expose Hydra through NGINX
  services.nginx.virtualHosts = {
    "hydra.${config.domains.root}" = {
      enableACME = true;
      forceSSL = true;
      
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.hydra.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };

  # Add a PostgreSQL database for Hydra
  services.postgresql = {
    enable = true;
    ensureDatabases = ["hydra"];
    ensureUsers = [
      {
        name = "hydra";
        ensurePermissions."DATABASE hydra" = "ALL PRIVILEGES";
      }
    ];
  };

  # Persist Hydra data
  environment.persistence."/persist".directories = [
    "/var/lib/hydra"
    "/var/lib/postgresql"
  ];
  
  # Open Prometheus metrics port for Tailscale access only
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9199 ];
}