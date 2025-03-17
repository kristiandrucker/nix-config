{
  config,
  pkgs,
  ...
}: let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;
in {
  imports = [./machines.nix];

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  # Enable Hydra service
  services.hydra = {
    enable = true;
    package = pkgs.hydra_unstable;
    hydraURL = "https://hydra.${config.domains.root}";
    notificationSender = "hydra@${config.domains.root}";
    port = 3000;
#    buildMachinesFiles = [];
    useSubstitutes = true;
#    dbi = "dbi:Pg:dbname=hydra;user=postgres;";
#    logo = null;
    
    # Configure Hydra with GitHub integration
    extraConfig =
      /*
      xml
      */
      ''
      <hydra_notify>
        <prometheus>
          listen_address = 0.0.0.0
          port = 9199
        </prometheus>
      </hydra_notify>
      '';
#        Include ${config.sops.secrets.hydra-gh-auth.path}
#        max_unsupported_time = 30
#        <githubstatus>
#          jobs = .*
#          useShortContext = true
#        </githubstatus>
#      '';
    extraEnv = {
      HYDRA_DISALLOW_UNFREE = "0";
    };
  };

  # Expose Hydra through NGINX
  services.nginx.virtualHosts = {
    "hydra.${config.domains.root}" = {
      enableACME = false;
      forceSSL = false;
      
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.hydra.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };

  users.users = {
    hydra-queue-runner.extraGroups = [hydraGroup];
    hydra-www.extraGroups = [hydraGroup];
  };

  # Persist Hydra data
  environment.persistence."/persist".directories = [
    "/var/lib/hydra"
  ];
  
  # Open Prometheus metrics port for Tailscale access only
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9198 9199 ];
}