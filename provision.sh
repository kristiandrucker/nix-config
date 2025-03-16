# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.core.config' --target-host nixos@10.1.0.97
# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.monitoring.config' --target-host nixos@10.1.0.111
# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.builder.config' --target-host nixos@10.1.0.81