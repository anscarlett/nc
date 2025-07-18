inputs: { config, pkgs, lib, ... }:
{
  # Minimal NixOS installer configuration
  system.stateVersion = "25.05";
  
  # Basic filesystem for installer
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  services.openssh.enable = true;
  users.users.root.password = "nixos";
  
  # Include installer modules
  imports = [
    ./modules/core
    ./modules/installer
  ];
}