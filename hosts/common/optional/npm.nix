{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    nodejs_23
    yarn
  ];
}
