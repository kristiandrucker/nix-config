# domain-templates.nix
{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  # Define our domain template function
  mkDomain = {
    name,
    uuid,
    nvramPath,
    memoryGiB ? 8,
    vcpus ? 4,
    cpuMode ? "host-passthrough",
    hostdev ? [],
    controller ? [],
    disks ? [],
    networks ? [],
    active ? true,
    emulator ? "${pkgs.qemu}/bin/qemu-system-x86_64",
  }: {
    inherit active;
    definition = inputs.NixVirt.lib.domain.writeXML {
      type = "kvm";
      name = name;
      uuid = uuid;

      os = {
        type = "hvm";
        arch = "x86_64";
        machine = "q35";
        boot = [{dev = "hd";} {dev = "network";}];
        loader = {
          readonly = true;
          type = "pflash";
          path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
        };
        nvram = {
          template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
          templateFormat = "raw";
          format = "raw";
          path = nvramPath;
        };
      };

      features = {
        acpi = {};
        apic = {};
      };

      cpu = {mode = cpuMode;};

      clock = {
        offset = "utc";
        timer = [
          {
            name = "rtc";
            tickpolicy = "catchup";
          }
          {
            name = "pit";
            tickpolicy = "delay";
          }
          {
            name = "hpet";
            present = false;
          }
        ];
      };

      memory = {
        count = memoryGiB;
        unit = "GiB";
      };

      memoryBacking = {
        source = {type = "memfd";};
        access = {mode = "shared";};
      };

      vcpu = {
        placement = "static";
        count = vcpus;
      };

      devices = {
        emulator = emulator;

        serial = {
          type = "pty";
          target = {
            type = "isa-serial";
            port = 0;
            model = {name = "isa-serial";};
          };
        };

        console = {
          type = "pty";
          target = {
            type = "serial";
            port = 0;
          };
        };

        # Default disk configuration that can be overridden
        disk =
          if builtins.length disks == 0
          then [
            {
              type = "volume";
              device = "disk";
              driver = {
                name = "qemu";
                type = "qcow2";
                cache = "none";
                discard = "unmap";
              };
              source = {
                pool = "default";
                volume = "${name}.qcow2";
              };
              target = {
                dev = "vda";
                bus = "virtio";
              };
            }
          ]
          else disks;

        # Default network configuration that can be overridden
        interface =
          if builtins.length networks == 0
          then [
            {
              type = "bridge";
              source = {bridge = "br-inf";};
            }
          ]
          else networks;

        graphics = {
          type = "vnc";
          port = -1;
          autoport = true;
          passwd = "guest";
          listen = {
            type = "address";
            address = "0.0.0.0";
          };
        };

        video = {
          model = {
            type = "virtio";
            heads = 1;
            primary = true;
          };
          #          address = {
          #            type = "pci";
          #            domain = "0x0000";
          #            bus = "0x07";
          #            slot = "0x00";
          #            function = "0x0";
          #          };
        };

        controller = controller;
        hostdev = hostdev;

        channel = [
          {
            type = "unix";
            target = {
              type = "virtio";
              name = "org.qemu.guest_agent.0";
            };
          }
        ];

        rng = {
          model = "virtio";
          backend = {
            model = "random";
            source = /dev/urandom;
          };
        };
      };
    };
  };
}
