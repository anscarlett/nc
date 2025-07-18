# VM configuration for testing
inputs: { config, pkgs, lib, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # VM-specific settings
  networking.hostName = hostname;
  
  # Boot configuration 
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # VM filesystem configuration
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  
  imports = [
    ../../../common.nix
    ../../../modules/core
    ../../../modules/desktop/hyprland
  ];
  
    # Users are automatically created by core module from homes directory
  # Override specific user settings
  users.users.adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  users.users.adrianscarlett-work.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Example: System-level secrets for testing (uncomment when needed)
  # age.secrets.test-data = {
  #   file = ./test-data.age;
  #   owner = "adrian";
  # };
  # Secrets definitions are in ./secrets.nix
}
