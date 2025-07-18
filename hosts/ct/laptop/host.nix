# CT Laptop configuration
inputs: { config, pkgs, lib, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # Use btrfs-flex disko preset for ct/laptop
  disko = (btrfsPreset {
    disk = "/dev/disk/by-id/ct-laptop-disk";
    enableImpermanence = true;
    enableHibernate = true;
    swapSize = "32G";
    luksName = "cryptlaptop";
    enableYubikey = true;
  }).disko;

  networking.hostName = hostname;
  
  imports = [
    ../../../common.nix
    ../../../modules/core
    ../../../modules/desktop
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];
  
  # Users are automatically created by core module from homes directory
  # Override specific settings for this host
  users.users = lib.mkMerge [
    # Auto-created users from core module
    config.users.users
    # Host-specific overrides
    {
      # Set password for the auto-discovered user (adrianscarlett-ct)
      adrianscarlett-ct.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
    }
  ];
}
