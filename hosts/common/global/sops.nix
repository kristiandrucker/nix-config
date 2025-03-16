{
  inputs,
  config,
  ...
}: let
  # Helper functions to get SSH host keys
  isEd25519 = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  # Configure SOPS with SSH keys
  sops = {
    # Use SSH host key as the age key for SOPS
    age.sshKeyPaths = map getKeyPath keys;
    
    # Default secrets location
    defaultSopsFile = ../secrets.yaml;
    
    # Ensure we store secrets in persisted locations
    age.generateKey = false;
  };
}