{
  config,
  pkgs,
  ...
}: {
  # Enable NVIDIA drivers and CUDA
  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };

  # Add CUDA
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.powerManagement.enable = true;

  # Add CUDA to your environment
  environment.systemPackages = with pkgs; [
    cudatoolkit
    ffmpeg
  ];
}
