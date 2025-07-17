# CT laptop configuration
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
  
  # User configuration - use the contextual username (adrianscarlett-ct)
  users.users.adrianscarlett-ct = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  };
  
  # Home Manager - use the CT adrianscarlett configuration
  home-manager.users.adrianscarlett-ct = import ../../../homes/ct/adrianscarlett/home.nix inputs;
}
