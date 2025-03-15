{ pkgs ? import <nixpkgs> {}, ... }:
{
  default = pkgs.mkShell {
    NIX_CONFIG = ''
      extra-experimental-features = nix-command flakes ca-derivations
      trusted-users = root kristian
      builders = ssh://root@192.168.64.2
      builders-use-substitutes = true
    '';
    nativeBuildInputs = with pkgs; [
      nix
      home-manager
      git
      sops
      ssh-to-age
      gnupg
      age
    ];
  };
}