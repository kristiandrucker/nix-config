{lib, ...}: {
  services.fail2ban = {
    enable = true;

    # Default jail settings
    jails = {
      # Enable SSH protection with mkForce to override the default
      sshd = lib.mkForce ''
        enabled = true
        maxretry = 5
        findtime = 1d
        bantime = 1d
      '';

      # Web server protection
      nginx-http-auth = ''
        enabled = true
        maxretry = 5
        findtime = 30m
        bantime = 2h
      '';
    };

    # Custom settings
    banaction = "iptables-multiport";
    ignoreIP = [
      "127.0.0.1/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "100.64.0.0/10" # Tailscale range
    ];
  };
}
