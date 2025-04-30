# This file (and the global directory) holds config that is used on all hosts
{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./locale.nix
    ./nix.nix
    ./base.nix
    ./openssh.nix
    ./sops.nix
    ./tailscale.nix
    ./docker.nix
    ./node-exporter.nix
    ./auto-upgrade.nix
    ./firewall.nix
    ./domains.nix
    ./optin-persistence.nix
    ./backup.nix
    ./time.nix
    ./memory.nix
  ];

  # Configure home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  # Configure nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];
}
