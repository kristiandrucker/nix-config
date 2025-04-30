{
  config,
  lib,
  pkgs,
  ...
}: {
  # AMD EPYC 3251 specific optimizations and power management

  # Enable CPU microcode updates for AMD
  hardware.cpu.amd.updateMicrocode = true;

  # Load AMD-specific kernel modules
  boot.kernelModules = [
    "kvm-amd" # KVM support for AMD virtualization
    "amd_pstate" # AMD P-State driver for better power management
    "msr" # Model-specific register access
    "cpuid" # CPU identification
  ];

  # Enable CPU frequency scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand"; # Changes frequency based on system load
    powertop.enable = true; # Tool for power consumption analysis and management
  };

  # Enable thermald for thermal management
  services.thermald.enable = true;

  # Enable TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      # CPU frequency scaling
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      SCHED_POWERSAVE_ON_AC = 0;
    };
  };

  # Enable auto-cpufreq for dynamic frequency scaling
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # Kernel parameters for AMD optimization
  boot.kernelParams = lib.mkAfter [
    "amd_pstate=active" # Enable active mode for AMD P-State driver
    "processor.max_cstate=5" # Limit C-states for better performance/power balance
    "idle=nomwait" # Disable mwait for idle, can help with power consumption
    "rcu_nocbs=0-15" # Exclude CPUs from RCU callback processing (assuming 16 threads)
    "transparent_hugepage=always" # Better performance for virtualization
  ];

  # Add monitoring tools for power management
  environment.systemPackages = with pkgs; [
    powertop
    s-tui # Terminal UI for monitoring CPU temperature, frequency, power, and load
    lm_sensors # Hardware monitoring tools
    htop # Process viewer with CPU per core view
  ];

  #  # Configure CPU scheduler for better performance
  boot.kernel.sysctl = lib.mkMerge [
    {
      "kernel.sched_migration_cost_ns" = 5000000; # Reduce task migration between CPUs
      "kernel.sched_autogroup_enabled" = 0; # Disable autogroup for server workloads
    }
  ];
}
