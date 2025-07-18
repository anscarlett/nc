# Rock5B configuration
inputs: { config, pkgs, lib, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # Rock5B specific configuration (ARM64/aarch64)
  # Note: System architecture is automatically detected as aarch64-linux
  # based on the hostname containing "rock5b"
  
  # ARM-specific boot configuration
  boot = {
    # Rock5B uses U-Boot, not systemd-boot
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;  # For ARM SBCs
    };
    
    # ARM kernel parameters
    kernelParams = [
      "console=ttyS2,1500000"  # Rock5B serial console
      "console=tty0"
    ];
  };
  
  # Use btrfs-flex disko preset for rock5b
  disko = (btrfsPreset {
    disk = "/dev/disk/by-id/rock5b-disk";
    enableImpermanence = false;
    enableHibernate = false;
    swapSize = null;
    luksName = "cryptrock5b";
    enableYubikey = false;
  }).disko;

  networking.hostName = hostname;
  
  imports = [
    ../../modules/core
    ../../modules/server
    # Optional: Add hardware-specific modules
  ];
  
  # Override core module boot settings for ARM
  boot.loader.systemd-boot.enable = inputs.nixpkgs.lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = inputs.nixpkgs.lib.mkForce false;
  
  # Users are automatically created by core module from homes directory
  # Override specific user settings
  users.users.adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  users.users.adrianscarlett-work.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Example: System-level secrets (uncomment when you set up secrets)
  # age.secrets.home-wifi = {
  #   file = ./home-wifi.age;
  #   owner = "root";
  #   group = "networkmanager";
  # };
  # Secrets definitions are in ./secrets.nix
}
