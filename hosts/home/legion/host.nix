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
    ../../modules/core
    ../../modules/desktop/hyprland
    # inputs.nixos-hardware.nixosModules.lenovo-legion  # Module may not exist
  ];
  
    # Users are automatically created by core module from homes directory
  # Override specific user settings
  users.users.adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  users.users.adrianscarlett-work.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Secrets configuration
  sops.secrets.mysecret = {
    sopsFile = ./secrets.yaml;
    path = "/persist/secrets/mysecret"; # Store secret in the secrets subvolume
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
