{
  lib,
  config,
  outputs,
  ...
}: let
  hosts = lib.attrNames outputs.nixosConfigurations;

  # Sops needs access to the keys before the persist dirs are even mounted; so
  # just persisting the keys won't work, we must point at /persist
  hasOptinPersistence = config.environment.persistence ? "/persist";
in {
  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    
    # Security settings
    settings = {
      # Disable password authentication
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      
      # Use the more secure protocol by default
      Protocol = 2;
      
      # Enable agent forwarding
      AllowAgentForwarding = true;
      
      # Enable TCP forwarding (for remote port forwards)
      AllowTcpForwarding = true;
      
      # Only use modern ciphers and keysig algorithms
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
      ];
      
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      
      # Allow StreamLocalBindUnlink for agent forwarding
      StreamLocalBindUnlink = true;
    };
    
    # Generate host keys on first boot
    hostKeys = [
      {
        path = "${lib.optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  programs.ssh = {
    # Each hosts public key
    knownHosts = lib.genAttrs hosts (hostname: {
      publicKeyFile = ../../${hostname}/ssh_host_ed25519_key.pub;
      extraHostNames =
        [
          "${hostname}.ts.${config.domains.root}"
        ]
        ++
        # Alias for localhost if it's the same host
        (lib.optional (hostname == config.networking.hostName) "localhost");
    });
  };

  # Automatically restart SSH on configuration changes
  systemd.services.sshd.restartTriggers = [
    config.environment.etc."ssh/sshd_config".source
  ];

   security.pam.sshAgentAuth = {
     enable = true;
     authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
   };
}