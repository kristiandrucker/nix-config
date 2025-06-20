{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  # Import our template modules
  domainTemplates = import ./templates/domain.nix {inherit lib pkgs inputs;};
  storageTemplates = import ./templates/storage.nix {inherit lib inputs;};
  networkTemplates = import ./templates/network.nix {inherit lib;};

  # Extract template functions
  inherit (domainTemplates) mkDomain;
  inherit (storageTemplates) mkQcowDisk mkRawDisk mkDirectDisk mkVolume;
  inherit (networkTemplates) mkBridgeNetwork mkNatNetwork mkDirectNetwork;
in {
  virtualisation.libvirt = {
    enable = true;

    connections."qemu:///system" = {
      pools = [
        {
          definition = inputs.NixVirt.lib.pool.writeXML {
            name = "default";
            uuid = "afa32edd-a316-4cc5-879d-b25ab3422cf7";
            type = "dir";
            target = {path = "/persist/var/lib/libvirt/images";};
          };
          active = true;
          volumes = [
            (mkVolume {
              name = "builder.raw";
              capacityGiB = 128;
            })
            (mkVolume {
              name = "core.raw";
              capacityGiB = 64;
            })
            (mkVolume {
              name = "infrastructure.raw";
              capacityGiB = 128;
            })
            (mkVolume {
              name = "media.raw";
              capacityGiB = 128;
            })
            (mkVolume {
              name = "monitoring.raw";
              capacityGiB = 128;
            })
#            (mkVolume {
#              name = "automation.qcow2";
#              capacityGiB = 64;
#            })
          ];
        }
      ];

      domains = [
        (
          mkDomain {
            name = "core";
            uuid = "7df328f3-fa25-49cf-a39a-acaad0902da8";
            vcpus = 4;
            memoryGiB = 16;
            nvramPath = "/persist/var/lib/libvirt/images/core.VARS.fd";
            disks = [
              (mkRawDisk {
                volume = "core.raw";
                target = "vda";
              })
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "bc:24:11:fa:50:75";
              })
            ];
          }
        )
        (
          mkDomain {
            name = "infrastructure";
            uuid = "155762bc-4f07-4e2c-a023-0449075f8164";
            vcpus = 4;
            memoryGiB = 32;
            nvramPath = "/persist/var/lib/libvirt/images/infrastructure.VARS.fd";
            disks = [
              (mkRawDisk {
                volume = "infrastructure.raw";
                target = "vda";
              })
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "bc:24:11:9c:70:cb";
              })
            ];
          }
        )
        (
          mkDomain {
            active = true;
            name = "monitoring";
            uuid = "f31c8194-260a-4b0e-956c-4c0ed0a7884f";
            vcpus = 4;
            memoryGiB = 16;
            nvramPath = "/persist/var/lib/libvirt/images/monitoring.nvram";
            disks = [
              (mkRawDisk {
                volume = "monitoring.raw";
                target = "vda";
              })
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "bc:24:11:2b:08:10";
              })
            ];
          }
        )
        (
          mkDomain {
            active = true;
            name = "media";
            uuid = "752413de-59a1-4000-b1a4-cf48a320076d";
            vcpus = 4;
            memoryGiB = 16;
            nvramPath = "/persist/var/lib/libvirt/images/media.nvram";
            disks = [
              (mkRawDisk {
                volume = "media.raw";
                target = "vda";
              })
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "bc:24:11:66:8b:cf";
              })
            ];
            controller = [
              {
                type = "pci";
                index = 0;
                model = "pcie-root";
              }
              {
                type = "pci";
                index = 1;
                model = "pcie-root-port";
                address = {
                  type = "pci";
                  domain = 0;
                  bus = 0;
                  slot = 1;
                  function = 0;
                };
              }
            ];
          }
        )
        (
          mkDomain {
            active = true;
            name = "builder";
            uuid = "aafc5193-e4b4-43f3-b40f-d2745f2139a8";
            vcpus = 4;
            memoryGiB = 16;
            nvramPath = "/persist/var/lib/libvirt/images/builder.nvram";
            disks = [
              (mkRawDisk {
                volume = "builder.raw";
                target = "vda";
              })
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "ba:e0:37:d0:62:71";
              })
            ];
          }
        )
        (
          mkDomain {
            active = true;
            name = "automation";
            uuid = "810e7616-b8cf-4f1d-8ebd-edb56cc8495e";
            vcpus = 2;
            memoryGiB = 4;
            nvramPath = "/persist/var/lib/libvirt/images/automation.nvram";
            disks = [
              (mkQcowDisk {
                volume = "haos_ova-15.2.qcow2";
                target = "vda";
              })
            ];
            hostdev = [
              {
                mode = "subsystem";
                type = "usb";
                managed = true;
                source = {
                  vendor.id = 4292;
                  product.id = 60000;
                };
              }
            ];
            networks = [
              (mkBridgeNetwork {
                bridge = "br-inf";
                mac = "ba:e0:37:d0:62:73";
              })
            ];
          }
        )
      ];
    };
  };

  environment.persistence."/persist".directories = [
    "/var/lib/libvirt/images"
  ];

  # Ensure libvirtd is enabled
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      verbatimConfig = ''
        nvram = [ "${pkgs.OVMF.fd}/FV/OVMF_CODE.fd:${pkgs.OVMF.fd}/FV/OVMF_VARS.fd" ]
        relaxed_acs_check = 1
        nographics_allow_host_audio = 1
      '';
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            #            secureBoot = true;
            tpmSupport = true;
          })
          .fd
        ];
      };
      # Needed for filesysystem passthrough
      vhostUserPackages = with pkgs; [virtiofsd];
    };
  };
}
