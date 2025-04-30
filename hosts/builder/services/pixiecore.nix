{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  sys = lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }: {
        imports = [
          (modulesPath + "/installer/netboot/netboot-minimal.nix")
          (modulesPath + "/profiles/qemu-guest.nix")
        ];
        config = {
          services.qemuGuest.enable = true;
          services.openssh = {
            enable = true;
            openFirewall = true;
          };

          environment.systemPackages = with pkgs; [
            borgbackup
          ];

          fileSystems."/media/backup" = {
            device = "10.1.0.32:/var/nfs/shared/Backups";
            fsType = "nfs";
            options = ["noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"];
          };

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkGCUcoWv3u3aU5PJXaz0geU87WTBw4T8fCSJN9c+yt"
          ];
        };
      })
    ];
  };

  build = sys.config.system.build;
in {
  services.pixiecore = {
    enable = true;
    openFirewall = true;
    dhcpNoBind = true;
    port = 8000;

    mode = "boot";
    kernel = "${build.kernel}/bzImage";
    initrd = "${build.netbootRamdisk}/initrd";
    cmdLine = "init=${build.toplevel}/init loglevel=4 console=tty0 console=ttyS0,115200n8";
    debug = true;
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [8000];
}
