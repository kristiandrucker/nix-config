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

            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
            };
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
    cmdLine = "init=${build.toplevel}/init loglevel=4";
    debug = true;
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [8000];
}
