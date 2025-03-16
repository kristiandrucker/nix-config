{
  lib,
  ...
}: {
  # Basic firewall configuration
  networking.firewall = {
    enable = lib.mkDefault true;
    allowPing = lib.mkDefault true;
    
    # Common ports
    allowedTCPPorts = lib.mkDefault [
      22   # SSH
    ];
    
    # For Tailscale
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [41641]; # Tailscale
    
    # Helper for Tailscale exit nodes
    checkReversePath = "loose";
  };
}