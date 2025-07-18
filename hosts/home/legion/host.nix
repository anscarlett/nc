# Home Legion configuration
inputs: { config, pkgs, lib, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # Use btrfs-flex disko preset for home/legion
  disko = (btrfsPreset {
    disk = "/dev/disk/by-id/legion-disk";
    enableImpermanence = true;
    enableHibernate = true;
    swapSize = null;
    luksName = "cryptroot";
    enableYubikey = true;
  }).disko;

  networking.hostName = hostname;
  
  imports = [
    ../../../common.nix
    ../../../modules/core
    ../../../modules/desktop
    # inputs.nixos-hardware.nixosModules.lenovo-legion  # Module may not exist
  ];
  
  # Users are automatically created by core module from homes directory
  # Override specific settings for this host
  users.users = lib.mkMerge [
    # Auto-created users from core module  
    config.users.users
    # Host-specific overrides
    {
      # Set password for the auto-discovered user
      adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
    }
  ];
  
  # Secrets configuration
  sops.secrets.mysecret = {
    sopsFile = ./secrets.yaml;
    path = "/persist/secrets/mysecret"; # Store secret in the secrets subvolume
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
