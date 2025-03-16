{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./auth-container.nix
  ];
}