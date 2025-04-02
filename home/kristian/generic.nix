{lib, ...}: {
  imports = [./global];

  # Disable impermanence for generic profile
  home.persistence = lib.mkForce {};
}
