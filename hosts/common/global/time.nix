{
  services.chrony = {
    enable = true;
    servers = [
      # Google's NTP servers
      "time.google.com iburst"
      "time1.google.com iburst"
      "time2.google.com iburst"
      "time3.google.com iburst"
      "time4.google.com iburst"

      # Cloudflare's NTP servers (very low latency)
      "time.cloudflare.com iburst"

      # European NTP servers for better latency from Dresden
      "0.de.pool.ntp.org iburst"
      "1.de.pool.ntp.org iburst"
    ];
    extraConfig = ''
      # Record the rate at which the system clock gains/losses time
      driftfile /var/lib/chrony/drift
      # Allow the system clock to be stepped in the first three updates
      makestep 1.0 3
      # Serve time locally
      local stratum 10
    '';
  };

  # Ensure the chrony data directory is persisted
  environment.persistence."/persist".directories = [
    "/var/lib/chrony"
  ];
}
