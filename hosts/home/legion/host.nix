# Legion Home Configuration
inputs: { config, lib, pkgs, ... }:
let
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
    ./common.nix
    ./modules/core
    ./modules/desktop
    # inputs.nixos-hardware.nixosModules.lenovo-legion  # Module may not exist
  ];
  
    # Users are automatically created by core module from homes directory
  # Override password for all auto-discovered users
  users.users = let
    # Get usernames from home directories
    autoUsers = import ../../../lib/auto-users.nix { inherit lib pkgs; };
    usernames = builtins.attrNames (autoUsers.mkUsers ../../../homes);
    # Create password overrides for each discovered user
    passwordOverrides = lib.genAttrs usernames (username: {
      hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
    });
  in passwordOverrides;
  
  # Secrets configuration
  sops.secrets.mysecret = {
    sopsFile = ./secrets.yaml;
    path = "/persist/secrets/mysecret"; # Store secret in the secrets subvolume
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
