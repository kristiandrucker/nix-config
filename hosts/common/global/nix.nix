{
  inputs,
  lib,
  ...
}: {
  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = ["nix-command" "flakes" "ca-derivations"];
      
      # Optimise store automatically
      auto-optimise-store = lib.mkDefault true;
      
      # Allow sudo users to mark the following values as trusted
      trusted-users = ["root" "@wheel"];
      
      # Only allow sudo users to manage the nix store
      allowed-users = ["root" "@wheel"];
      
      # Setup binary caches
      substituters = [
        "http://cache.drkr.io"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.drkr.io:KFcXrcoqTQdwwoUgzmKTLg1x2Hz60u5w1GqwBWXURQM="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Fallback quickly if substituters are not available
      connect-timeout = 5;
      
      # Set TTL for negative lookups to avoid unnecessary requests
#      negative-ttl = 10;

      # Set a higher buffer size for downloads
      download-buffer-size = 134217728;
      
      # Show more log output
      log-lines = 25;
    };
    
    # Clean up old generations automatically
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}