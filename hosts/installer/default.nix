# NixOS installer configuration
{ modulesPath, pkgs, lib, ... }:

{
  imports = [
    # Base installer image
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    # Our custom installer modules
    ../../modules/installer
    ../../modules/installer/stage-1.nix
  ];

  # Force loading of 9P modules
  boot.kernelModules = [ "9p" "9pnet" "9pnet_virtio" ];
  boot.supportedFilesystems = [ "9p" ];

  # Enable OpenSSH for remote installation if needed
  services.openssh.enable = true;

  # Auto-login for convenience
  services.getty.autologinUser = "nixos";

  # System settings
  system.stateVersion = "25.05";
}
