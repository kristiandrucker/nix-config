# storage-templates.nix
{
  lib,
  inputs,
  ...
}:
with lib; {
  # Helper functions for common disk types
  mkQcowDisk = {
    pool ? "default",
    volume,
    target ? "vda",
    cache ? "none",
    discard ? "unmap",
  }: {
    type = "volume";
    device = "disk";
    driver = {
      name = "qemu";
      type = "qcow2";
      cache = cache;
      discard = discard;
    };
    source = {
      pool = pool;
      volume = volume;
    };
    target = {
      dev = target;
      bus = "virtio";
    };
  };

  mkRawDisk = {
    pool ? "default",
    volume,
    target ? "vda",
    cache ? "none",
  }: {
    type = "volume";
    device = "disk";
    driver = {
      name = "qemu";
      type = "raw";
      cache = cache;
    };
    source = {
      pool = pool;
      volume = volume;
    };
    target = {
      dev = target;
      bus = "virtio";
    };
  };

  mkDirectDisk = {
    path,
    target ? "vda",
    cache ? "none",
  }: {
    type = "file";
    device = "disk";
    driver = {
      name = "qemu";
      type = "raw";
      cache = cache;
    };
    source = {
      file = path;
    };
    target = {
      dev = target;
      bus = "virtio";
    };
  };

  mkVolume = {
    name,
    capacityGiB ? 64,
    format ? "raw",
  }: {
    definition = inputs.NixVirt.lib.volume.writeXML {
      name = name;
      target = {
        format.type = format;
      };
      capacity = {
        count = capacityGiB;
        unit = "GB";
      };
    };
  };
}
