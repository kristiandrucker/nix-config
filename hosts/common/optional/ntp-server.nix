{
  config,
  pkgs,
  ...
}: {
  # Configure as an NTP server
  services.chrony = {
    enable = true;

    # Allow serving time to the local network
    extraConfig = ''
      # Allow NTP client access from local network
      allow 10.0.0.0/8
      allow 172.16.0.0/12
      allow 192.168.0.0/16
      allow 100.64.0.0/10  # Tailscale

      # Server configuration
      driftfile /var/lib/chrony/drift
      logdir /var/log/chrony

      # Use more reliable NTP servers
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst
      server 3.pool.ntp.org iburst

      # Record the rate at which the system clock gains/losses time
      driftfile /var/lib/chrony/drift

      # Allow the system clock to be stepped in the first three updates
      makestep 1.0 3

      # Enable kernel synchronization of the real-time clock (RTC)
      rtcsync
    '';
  };

  # Open firewall for NTP
  networking.firewall = {
    allowedUDPPorts = [123]; # NTP
  };

  # Ensure persistent storage
  environment.persistence."/persist".directories = [
    "/var/lib/chrony"
  ];
}
