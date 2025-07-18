# Work Laptop configuration
inputs: { config, lib, pkgs, ... }:
let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # Use btrfs-flex disko preset for work/laptop
  disko = (btrfsPreset {
    disk = "/dev/disk/by-id/work-laptop-disk";
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
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-intel-gen5
  ];
  
  # Users are automatically created by core module from homes directory
  # Override specific user settings
  users.users.adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  users.users.adrianscarlett-work.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Example: System-level secrets (uncomment when you set up secrets)
  # age.secrets.work-wifi = {
  #   file = ./work-wifi.age;
  #   owner = "root";
  #   group = "networkmanager";
  #   mode = "0640";
  # };
  # Secrets definitions are in ./secrets.nix
}
