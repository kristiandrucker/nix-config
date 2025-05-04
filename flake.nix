{
  description = "My NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.drkr.io"
    ];
    extra-trusted-public-keys = [
      "cache.drkr.io:KFcXrcoqTQdwwoUgzmKTLg1x2Hz60u5w1GqwBWXURQM="
    ];
  };

  inputs = {
    # Nix ecosystem
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default-linux";
    deploy-rs = {
      url = github:serokell/deploy-rs;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "github:kristiandrucker/nixvirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    systems,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    supportedSystems = (import systems) ++ ["aarch64-darwin"];
    forEachSystem = f: lib.genAttrs supportedSystems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs supportedSystems (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );

    # Helper function to create NixOS configurations with common modules
    mkNixosSystem = hostPath: extraModules:
      lib.nixosSystem {
        modules =
          [
            # Import the Envoy module directly (not as a list)
            ./modules/envoy.nix

            # Import the base host configuration
            hostPath
          ]
          ++ extraModules;
        specialArgs = {
          inherit inputs outputs;
        };
      };
  in {
    inherit lib;
    nixosModules =
      import ./modules
      // {
        envoy = import ./modules/envoy.nix;
      };
    #    homeManagerModules = import ./modules/home-manager;

    overlays = [(import ./overlays/plex.nix)];
    #    hydraJobs = import ./hydra.nix {inherit inputs outputs;};

    #    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forEachSystem (pkgs: {default = (import ./shell.nix {inherit pkgs;}).default;});
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    nixosConfigurations = {
      # Core Server
      core = mkNixosSystem ./hosts/core [];

      # Home Automation Server
      automation = mkNixosSystem ./hosts/automation [];

      # Media server
      media = mkNixosSystem ./hosts/media [];

      # Builder with Hydra and Nix cache
      builder = mkNixosSystem ./hosts/builder [];

      # Infrastructure VM with DBs
      infrastructure = mkNixosSystem ./hosts/infrastructure [];

      # Bare metal host
      zeus = mkNixosSystem ./hosts/zeus [];

      # Monitoring server with Prometheus, Grafana, Loki, Tempo
      monitoring = mkNixosSystem ./hosts/monitoring [];
    };

    homeConfigurations = {
      "kristian@core" = lib.homeManagerConfiguration {
        modules = [./home/kristian/generic.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      "kristian@monitoring" = lib.homeManagerConfiguration {
        modules = [./home/kristian/generic.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      "kristian@media" = lib.homeManagerConfiguration {
        modules = [./home/kristian/generic.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      "kristian@infrastructure" = lib.homeManagerConfiguration {
        modules = [./home/kristian/generic.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
    };

    deploy.nodes = {
      core = {
        hostname = "core.ts.drkr.io";
        fastConnection = false;
        profiles = {
          default = {
            sshUser = "kristian";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.core;
            user = "root";
          };
        };
      };
      monitoring = {
        hostname = "monitoring.ts.drkr.io";
        fastConnection = false;
        profiles = {
          default = {
            sshUser = "kristian";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.monitoring;
            user = "root";
          };
        };
      };
      media = {
        hostname = "media.ts.drkr.io";
        fastConnection = false;
        profiles = {
          default = {
            sshUser = "kristian";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.media;
            user = "root";
          };
        };
      };
      infrastructure = {
        hostname = "infrastructure.ts.drkr.io";
        fastConnection = false;
        profiles = {
          default = {
            sshUser = "kristian";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.infrastructure;
            user = "root";
          };
        };
      };
    };
  };
}
