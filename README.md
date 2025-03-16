# NixOS Configuration for drkr.io

This repository contains NixOS configurations for multiple machines in the drkr.io domain:

- `core`: Base server providing authentication services
- `media`: Media server with NVIDIA Quadro P400 driver support
- `builder`: Build server with Hydra CI and Nix cache
- `public-1` and `public-2`: Public-facing VM servers with DNS (Blocky) and NTP services
- `dvr`: Digital Video Recorder running on a Raspberry Pi
- `monitoring`: Monitoring server with Prometheus, Grafana, Loki, and Tempo

## Bootstrapping a New Machine

1. Install NixOS following the [official guide](https://nixos.org/manual/nixos/stable/index.html#sec-installation)
2. Clone this repository:
   ```bash
   sudo mkdir -p /etc/nixos/
   git clone https://github.com/yourusername/nix-config.git /etc/nixos
   ```
3. Create a hardware configuration for your machine:
   ```bash
   nixos-generate-config --show-hardware-config > /etc/nixos/hosts/your-machine/hardware-configuration.nix
   ```
4. Customize your configuration:
   - Copy an existing configuration from a similar machine
   - Update hostname and any hardware-specific settings
5. Setup SOPS (see below)
6. Apply the configuration:
   ```bash
   nixos-rebuild switch --flake .#your-machine
   ```

## SOPS Setup Guide

This configuration uses [SOPS-Nix](https://github.com/mic92/sops-nix) for secret management. The setup has been completed with your AGE key, and a comprehensive guide is available in [SOPS-SETUP.md](SOPS-SETUP.md).

### Current SOPS Setup

1. Your personal AGE key is configured at `~/.config/sops/age/keys.txt`
   - Public key: `age198e00r627fttqxts3qmdrvenc60uw6e468rpnp0eh9juprps6gcq2vgh5h`

2. The `.sops.yaml` file is configured to encrypt secrets for:
   - You personally (for local development)
   - Each machine using its SSH host key (for production)

3. Secret files are set up at:
   - `hosts/common/secrets.yaml` - Shared secrets for all machines
   - `hosts/<machine>/secrets.yaml` - Machine-specific secrets

### How to Use Secrets

1. **View or edit encrypted secrets**:
   ```bash
   sops hosts/common/secrets.yaml
   sops hosts/core/secrets.yaml
   ```

2. **Reference secrets in configuration**:
   ```nix
   # Define the secret
   sops.secrets."tailscale/auth_key" = {
     owner = "root";
     group = "root";
     mode = "0400";
   };
   
   # Use the secret
   services.tailscale = {
     enable = true;
     authKeyFile = config.sops.secrets."tailscale/auth_key".path;
   };
   ```

3. **Secret access via containers**:
   Mount secrets into containers:
   ```nix
   volumes = [
     "${config.sops.secrets."auth_container/admin_password".path}:/run/secrets/admin_password"
   ];
   ```

### Machine Setup

For each new machine:

1. First boot the machine with SSH host keys generated
   ```bash
   nixos-rebuild switch --flake .#your-machine
   ```

2. Get the AGE key from the SSH host key:
   ```bash
   ssh root@your-machine "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
   ```

3. Update `.sops.yaml` with the machine's AGE key

4. Re-encrypt all relevant secrets:
   ```bash
   sops updatekeys hosts/your-machine/secrets.yaml
   sops updatekeys hosts/common/secrets.yaml
   ```

See [SOPS-SETUP.md](SOPS-SETUP.md) for complete details on adding new machines or rotating keys.

## SSH Agent Forwarding

This configuration forwards your SSH agent to remote machines. To use:

1. Start SSH agent and add your key:
   ```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/id_ed25519
   ```

2. Connect to any machine with agent forwarding:
   ```bash
   ssh your-machine
   ```

3. Use your local SSH key on the remote machine:
   ```bash
   ssh-add -l  # Should show your key
   git clone git@github.com:your-private-repo/example.git  # Works!
   ```

## Adding New Machines

1. Create a new directory for the machine:
   ```bash
   mkdir -p hosts/new-machine/services
   ```

2. Create basic configuration files:
   ```bash
   cp hosts/core/default.nix hosts/new-machine/
   ```

3. Generate hardware configuration:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/new-machine/hardware-configuration.nix
   ```

4. Add the machine to `flake.nix`

5. Set up SOPS keys for the machine

6. Apply the configuration:
   ```bash
   nixos-rebuild switch --flake .#new-machine
   ```