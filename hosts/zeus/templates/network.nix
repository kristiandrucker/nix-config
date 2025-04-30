# network-templates.nix
{lib, ...}:
with lib; {
  # Helper function for network interfaces
  mkBridgeNetwork = {
    bridge ? "br-inf",
    model ? "virtio",
    mac ? null,
  }:
    {
      type = "bridge";
      source = {bridge = bridge;};
      model = {type = model;};
    }
    // (
      if mac != null
      then {mac = {address = mac;};}
      else {}
    );

  mkNatNetwork = {
    network ? "default",
    model ? "virtio",
    mac ? null,
  }:
    {
      type = "network";
      source = {network = network;};
      model = {type = model;};
    }
    // (
      if mac != null
      then {mac = {address = mac;};}
      else {}
    );

  mkDirectNetwork = {
    dev,
    mode ? "bridge",
    model ? "virtio",
    mac ? null,
  }:
    {
      type = "direct";
      source = {
        dev = dev;
        mode = mode;
      };
      model = {type = model;};
    }
    // (
      if mac != null
      then {mac = {address = mac;};}
      else {}
    );
}
