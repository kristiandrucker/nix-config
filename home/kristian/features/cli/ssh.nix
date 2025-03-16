{
  outputs,
  lib,
  config,
  ...
}: let
  # Get a list of hostnames from nixos configurations
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  # Get a list of hostnames from home-manager configurations
  homeConfigs = map (n: lib.last (lib.splitString "@" n)) (builtins.attrNames outputs.homeConfigurations);
  # Combine both lists and remove duplicates
  hostnames = lib.unique (homeConfigs ++ nixosConfigs);
in {
  # We'll handle persistence in the global config

  programs.ssh = {
    enable = true;
    
    # Use a directory for known hosts to make persistence easier
    userKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/hosts";
    
    # Enable multiplexing for faster connections
    controlMaster = "auto";
    controlPath = "${config.home.homeDirectory}/.ssh/control/%r@%h:%p";
    controlPersist = "30m";
    
    # Global SSH configuration
    extraConfig = ''
      AddKeysToAgent yes
      ServerAliveInterval 60
      ServerAliveCountMax 5
    '';
    
    # Configure all hosts with agent forwarding
    matchBlocks = {
      # Match all our managed hosts
      "managed-hosts" = {
        host = lib.concatStringsSep " " hostnames;
        forwardAgent = true;
        extraOptions = {
          # Always use StreamLocalBindUnlink for SSH agent forwarding
          StreamLocalBindUnlink = "yes";
        };
      };
      
      # Match all hosts
      "*" = {
        # Forward SSH agent by default
        forwardAgent = true;
      };
    };
  };

  # Create SSH control directory for multiplexing
  home.file.".ssh/control/.keep".text = "";
}