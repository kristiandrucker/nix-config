{pkgs ? import <nixpkgs> {}, ...}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations; extra-trusted-users=kristian";
    nativeBuildInputs = with pkgs; [
      nix
      nixos-rebuild
      home-manager
      git

      sops
      ssh-to-age
      gnupg
      age
    ];
  };
}