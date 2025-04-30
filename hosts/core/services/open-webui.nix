{
  config,
  pkgs,
  lib,
  ...
}: let
  version = "0.6.5";
in {
  virtualisation.oci-containers.containers = {
    "open-webui" = {
      image = "ghcr.io/open-webui/open-webui:${version}";
      autoStart = true;
      ports = [
        "127.0.0.1:8080:8080" # Only expose locally
      ];
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_URL = "chat.drkr.io";
        ENABLE_SIGNUP = "false";
        ENABLE_OLLAMA_API = "false";
        ENABLE_OAUTH_SIGNUP = "true";
        OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
        OAUTH_PROVIDER_NAME = "SSO";
        OPENID_PROVIDER_URL = "https://auth.drkr.io/.well-known/openid-configuration";
        OAUTH_CLIENT_ID = "3e394f6d-e546-4a08-898a-63acc579130e";
        OAUTH_CLIENT_SECRET = "kRhun9Qj2WrEuoiwhmU57MYTiGvkicfn";
        OAUTH_SCOPES = "openid email profile groups";
        OPENID_REDIRECT_URI = "https://chat.drkr.io/oauth/oidc/callback";
      };
      # Mount a persistent volume for data and secrets
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/persist/mnt/data/open-webui/data:/app/backend/data"
      ];
    };
  };

  services.nginx.virtualHosts = {
    "chat.${config.domains.root}" = {
      forceSSL = true;
      useACMEHost = "drkr.io";
      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
        extraConfig = "
          proxy_buffering off;
          proxy_cache off;
          proxy_set_header Connection '';
          chunked_transfer_encoding off;";
      };
    };
  };

  environment.persistence."/persist".directories = [
    "/mnt/data/open-webui"
  ];
}
