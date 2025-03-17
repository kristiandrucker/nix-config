{
  lib,
  config,
  ...
}: {
  # Configure SOPS secret for Tailscale auth key
  sops.secrets."tailscale/auth_key" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Enable Tailscale service
  services.tailscale = {
    enable = true;
    
    # Use client routing features
    useRoutingFeatures = lib.mkDefault "client";
    
    # Use the auth key from sops
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    
    # Additional flags for tailscale up
    extraUpFlags = [
      "--accept-dns=true"
      "--webclient=true"
    ];
  };
  
  # Open required firewall ports
  networking.firewall = {
    # Always allow traffic from your Tailscale network
    trustedInterfaces = ["tailscale0"];
    
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [41641];
    
    # Facilitate connection sharing
    checkReversePath = "loose";
  };
  
  # Persist Tailscale state
  environment.persistence."/persist".directories = [
    "/var/lib/tailscale"
  ];
}