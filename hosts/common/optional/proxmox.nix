{ outputs, ... } : {
  boot = {
    kernelParams = [ "console=ttyS0" ];
    initrd.availableKernelModules = [
      "uas"
      "virtio_blk"
      "virtio_pci"
    ];
  };
  services.qemuGuest.enable = true;
}