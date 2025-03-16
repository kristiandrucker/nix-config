# SOPS Secret Management Setup

This guide explains how to set up and use SOPS for secret management in this NixOS configuration.

## Your Current Setup

1. You have an AGE key generated at `~/.config/sops/age/keys.txt`
2. Your public key is: `age198e00r627fttqxts3qmdrvenc60uw6e468rpnp0eh9juprps6gcq2vgh5h`
3. A basic `.sops.yaml` configuration is set up to use your key for encryption

## How to Set Up Host Keys Using SSH Keys

When deploying to a new NixOS host, SOPS-NIX will automatically use the host's SSH Ed25519 keys as AGE keys. This is configured in `/hosts/common/global/sops.nix`.

### For Each New Host:

1. **Boot the new host with an initial NixOS configuration** that includes SSH and SOPS-NIX

2. **Get the SSH host public key**:
   ```bash
   ssh root@new-host "cat /etc/ssh/ssh_host_ed25519_key.pub"
   ```

3. **Convert the SSH key to an AGE key**:
   ```bash
   ssh root@new-host "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
   ```
   
   This requires the `ssh-to-age` tool which you can install via:
   ```bash
   nix-shell -p ssh-to-age
   ```

4. **Add the AGE key to your `.sops.yaml`**:
   Update the `.sops.yaml` file by replacing the placeholder for the host with the actual AGE key.
   
   For example, change:
   ```yaml
   - &core age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   
   To:
   ```yaml
   - &core age1abcdefghijklmnopqrstuvwxyz0123456789abcdefghijkl
   ```

5. **Re-encrypt your secrets**:
   After updating the `.sops.yaml` file with the new host key, re-encrypt any secrets that should be accessible to that host:
   
   ```bash
   sops updatekeys hosts/core/secrets.yaml
   sops updatekeys hosts/common/secrets.yaml  # Since all hosts need common secrets
   ```

## Using SOPS Secrets in NixOS Configuration

To use a SOPS-encrypted secret in your NixOS configuration:

1. **Define the secret in your NixOS module**:
   ```nix
   {
     sops.secrets."tailscale/auth_key" = {
       # Optional: specify a different path than the default
       path = "/run/secrets/tailscale_auth_key";
       # Optional: specify file permissions
       mode = "0400";
       # Optional: specify owner
       owner = "tailscale";
     };
   }[grafana.nix](hosts/monitoring/services/grafana.nix)
   ```
[tempo.nix](hosts/monitoring/services/tempo.nix)
2. **Reference the secret in your services**:
   ```nix
   {
     services.tailscale = {
       enable = true;
       authKeyFile = config.sops.secrets."tailscale/auth_key".path;
     };
   }
   ```

## Secret File Format

SOPS uses a simple YAML format for secrets:

```yaml
# This is an example of what your unencrypted secrets look like
service_name:
  secret_key: "secret_value"
another_service:
  password: "another_secret"
```

When encrypted, these become binary blobs that can only be decrypted by systems with the appropriate keys.

## Rotating Host Keys

If you need to change a host's SSH key, follow these steps:

1. Generate a new key on the host
2. Convert it to an AGE key
3. Update the `.sops.yaml` file with the new key
4. Re-encrypt all relevant secrets with `sops updatekeys`

## Maintaining Your Key

Keep your personal AGE key (`~/.config/sops/age/keys.txt`) safe and backed up. This key is used to decrypt all secrets on your local machine.