{pkgs ? import <nixpkgs> {}, ...}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
    nativeBuildInputs = with pkgs; [
      nix
      nixos-rebuild
      home-manager
      git

      sops
      ssh-to-age
      gnupg
      age
      alejandra
    ];
  };
}