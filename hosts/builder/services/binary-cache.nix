{
  config,
  pkgs,
  ...
}: {
  # Setup binary cache server
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/persist/var/cache-key/secret-key";
  };

  # Nix cache served through nginx
  services.nginx = {
    virtualHosts = {
      "cache.${config.domains.root}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };

  # Ensure cache key directory exists
  systemd.tmpfiles.rules = [
    "d /persist/var/cache-key 0750 root root - -"
  ];

  # Create cache signing key if it doesn't exist
  system.activationScripts.createNixServeKeys = ''
    if [ ! -f /persist/var/cache-key/secret-key ]; then
      mkdir -p /persist/var/cache-key
      ${pkgs.nix}/bin/nix-store --generate-binary-cache-key cache.${config.domains.root} /persist/var/cache-key/secret-key /persist/var/cache-key/public-key
      cat /persist/var/cache-key/public-key
    fi
  '';
}