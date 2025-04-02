# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.core.config' --target-host root@10.1.0.118
# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.monitoring.config' --target-host root@10.1.0.124
# nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.builder.config' --target-host root@10.1.0.81
#nix run github:nix-community/nixos-anywhere -- --flake '.#nixosConfigurations.media.config' --target-host root@10.1.0.206