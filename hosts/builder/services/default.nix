{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hydra
    ./binary-cache.nix
  ];
}