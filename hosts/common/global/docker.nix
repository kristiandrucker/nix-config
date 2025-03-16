{
  pkgs,
  ...
}: {
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    
    # Run dockerd with logs to journald instead of file
    enableOnBoot = true;
    logDriver = "journald";
    
    # Recommended settings for containers
    daemon.settings = {
      log-driver = "journald";
      data-root = "/var/lib/docker";
      storage-driver = "overlay2";
      iptables = false;
      
      # Fix for recent Docker versions
      features = {
        buildkit = true;
      };
    };
  };
  
  # Install docker-compose
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # Ensure docker state persists across reboots
  environment.persistence."/persist".directories = [
    "/var/lib/docker"
  ];
  
  # Add user to the docker group
  users.users.kristian.extraGroups = ["docker"];
}