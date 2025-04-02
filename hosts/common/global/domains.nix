{
  # Define domain settings
  lib,
  ...
}: {
  # Set global networking domains
  config = {
    networking.domain = "drkr.io";

    # Set the domain values
    domains = {
      root = "drkr.io";
      tailscale = "ts.drkr.io";
    };
  };

  # Export the domain as a system-wide NixOS option
  options.domains = {
    root = lib.mkOption {
      type = lib.types.str;
      default = "drkr.io";
      description = "The root domain for all services";
    };

    tailscale = lib.mkOption {
      type = lib.types.str;
      default = "ts.drkr.io";
      description = "The domain for Tailscale services";
    };
  };
}
