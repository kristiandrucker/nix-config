{
  self,
  config,
  lib,
  pkgs,
  ...
}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "certs@drkr.io";

    certs."drkr.io" = {
      domain = "drkr.io";
      extraDomainNames = ["*.drkr.io"];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cf-dns-token.path;
      };
    };
  };

  # Persist Cert data
  environment.persistence."/persist".directories = [
    "/var/lib/acme"
  ];

  # Setup SOPS secret for dns token
  sops.secrets.cf-dns-token = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  users.users.nginx.extraGroups = ["acme"];
}
