{pkgs, ...}: {
  nix.buildMachines = [
    {
      hostName = "localhost";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
      ];
      maxJobs = 4;
      supportedFeatures = [
        "kvm"
        "nixos-test"
        "benchmark"
        "big-parallel"
      ];
    }
  ];
}
