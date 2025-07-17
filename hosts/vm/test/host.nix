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
  
  # Simple disk configuration for VM testing
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
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
  
  # Home Manager configuration for the VM user
  home-manager.users.adrian = import ../../../homes/home/adrian/home.nix inputs;
  
  # VM test user
  users.users.adrian = {
    hashedPassword = "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  
  # Enable root login for testing
  users.users.root.password = "nixos";
}
