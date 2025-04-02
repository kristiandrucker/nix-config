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
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in {
    inherit lib;
    nixosModules = import ./modules/nixos;
    #    homeManagerModules = import ./modules/home-manager;

    #    overlays = import ./overlays {inherit inputs outputs;};
    hydraJobs = import ./hydra.nix {inherit inputs outputs;};

    #    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    nixosConfigurations = {
      # Core Server
      core = lib.nixosSystem {
        modules = [./hosts/core];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # Media server with NVIDIA drivers
      media = lib.nixosSystem {
        modules = [./hosts/media];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # Builder with Hydra and Nix cache
      builder = lib.nixosSystem {
        modules = [./hosts/builder];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      #        # Public-facing VM servers with DNS and NTP
      #        public-1 = lib.nixosSystem {
      #            modules = [./hosts/public-1];
      #            specialArgs = {
      #                inherit inputs outputs;
      #            };
      #        };
      #
      #        public-2 = lib.nixosSystem {
      #            modules = [./hosts/public-2];
      #            specialArgs = {
      #                inherit inputs outputs;
      #            };
      #        };
      #
      #        # Digital Video Recorder (Raspberry Pi)
      #        dvr = lib.nixosSystem {
      #            modules = [./hosts/dvr];
      #            specialArgs = {
      #                inherit inputs outputs;
      #            };
      #        };

      # Monitoring server with Prometheus, Grafana, Loki, Tempo
      monitoring = lib.nixosSystem {
        modules = [./hosts/monitoring];
        specialArgs = {
          inherit inputs outputs;
        };
      };
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
    };
  };
}
