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
  
  # Users - manually created for now (can be automated later)
  users.users = {
    adrian = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
      shell = pkgs.zsh;
      password = "adrian";  # Simple password for VM testing
    };
    
    # Enable root login for testing
    root.password = "nixos";
  };
  
  # Home Manager - specify which config to use
  home-manager.users.adrian = import ../../../homes/home/adrian/home.nix inputs;
}
