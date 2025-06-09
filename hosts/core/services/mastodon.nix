{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets."mastodon/db_pass" = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  sops.secrets."mastodon/otp_secret" = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  services.mastodon = {
    enable = true;
    configureNginx = true;
    localDomain = "social.drkr.io";
    streamingProcesses = 3;
    smtp.fromAddress = "noreply@mg.drkr.io";
    extraConfig.SINGLE_USER_MODE = "false";
    extraConfig.REGISTRATIONS_MODE = "open";
    mediaAutoRemove.enable = false;
    otpSecretFile = config.sops.secrets."mastodon/otp_secret".path;
    database = {
      createLocally = false;
      host = "pg.drkr.io";
      passwordFile = config.sops.secrets."mastodon/db_pass".path;
    };
  };

  environment.persistence."/persist".directories = [
    "/var/lib/mastodon/public-system"
  ];

  services.nginx.virtualHosts = {
    "social.${config.domains.root}" = {
      enableACME = lib.mkForce false;
      useACMEHost = "drkr.io";
    };
  };
}
