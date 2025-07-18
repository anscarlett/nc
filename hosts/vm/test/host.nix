# VM configuration for testing
inputs: { config, pkgs, lib, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # VM-specific settings
  networking.hostName = hostname;
  
  # Enable VM guest additions
  virtualisation.vmware.guest.enable = lib.mkDefault false;
  virtualisation.virtualbox.guest.enable = lib.mkDefault false;
  
  # VM configuration 
  virtualisation.memorySize = 4096;
  virtualisation.cores = 2;
  virtualisation.graphics = true;
  
  # Force VM to use disko disk layout
  virtualisation.useBootLoader = true;
  virtualisation.useEFIBoot = true;
   
  # Boot configuration for VM
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  
  imports = [
    ../../../common.nix
    ../../../modules/core
    ../../../modules/desktop/hyprland
  ];
  
  # Users are automatically created by core module from homes directory
  # Override specific settings for VM testing
  users.users = lib.mkMerge [
    # Auto-created users from core module
    config.users.users
    # VM-specific overrides
    {
      # Simple passwords for VM testing
      adrian.password = lib.mkForce "adrian";
      root.password = lib.mkForce "nixos";
    }
  ];
}
