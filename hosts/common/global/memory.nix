{lib, ...}: {
  # Configure swap with zram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Configure OOM killer to be more aggressive with low-priority processes
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.overcommit_memory" = lib.mkForce 1;
    "vm.overcommit_ratio" = 50;
  };
}
