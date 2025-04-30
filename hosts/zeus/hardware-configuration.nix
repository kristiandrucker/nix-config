{
  modulesPath,
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    #    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ../common/optional/ephemeral-btrfs.nix
  ];

  networking.bonds = {
    "bond0" = {
      interfaces = ["eno1" "eno2" "eno3" "eno4"];
      driverOptions = {
        mode = "802.3ad";
        miimon = "100";
        lacp_rate = "fast";
        xmit_hash_policy = "layer3+4";
      };
    };
  };

  # Network bridge configuration
  networking.bridges = {
    "br-inf" = {
      interfaces = ["bond0"];
    };
  };

  # Static IP configuration for the bridge
  networking.interfaces."br-inf" = {
    ipv4.addresses = [
      {
        address = "10.1.0.10";
        prefixLength = 24;
      }
    ];
  };

  # Default gateway configuration
  networking.defaultGateway = {
    address = "10.1.0.1";
    interface = "br-inf";
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.netdev_max_backlog" = 30000;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  #  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;

  #  boot.kernelPatches = [{
  #    name = "iommu-stress";
  #    patch = null;
  #    extraConfig = ''
  #      IOMMU_STRESS y
  #    '';
  #  }];

  boot = {
    initrd.availableKernelModules = ["ata_piix" "uhci_hcd"];
    initrd.kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci"];
    kernelModules = ["kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci"];
    kernelParams = [
      "console=tty0"
      "console=ttyS1,115200n8"
      "amd_iommu=on"
      "iommu=pt"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Enable KVM virtualization
  virtualisation.libvirt.enable = true;

  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        esp = {
          name = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        core = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-L${config.networking.hostName}"];
            postCreateHook = ''
              MNTPOINT=$(mktemp -d)
              mount -t btrfs "${config.disko.devices.disk.main.content.partitions.core.device}" "$MNTPOINT"
              trap 'umount $MNTPOINT; rm -d $MNTPOINT' EXIT
              btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
            '';
            subvolumes = {
              "/root" = {
                mountOptions = ["compress=zstd"];
                mountpoint = "/";
              };
              "/nix" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/nix";
              };
              "/persist" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/persist";
              };
              "/swap" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/swap";
                swap.swapfile = {
                  size = "8196M";
                  path = "swapfile";
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/persist".neededForBoot = true;
}
