{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./prometheus.nix
    ./grafana.nix
    ./loki.nix
    ./otel.nix
    ./tempo.nix
  ];
}