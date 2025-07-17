# Home Legion configuration
inputs: { config, pkgs, lib, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
  
  # Extract username from the context - we're in hosts/home/legion
  # Look for directories with home.nix files in homes/home/*
  homesForContext = builtins.readDir ../../../homes/home;
  potentialUsers = builtins.attrNames (lib.filterAttrs (name: type: type == "directory") homesForContext);
  actualUsers = builtins.filter (name: 
    builtins.pathExists (../../../homes/home + "/${name}/home.nix")
  ) potentialUsers;
  # Use the full contextual username (e.g., "adrian-home")
  baseUsername = if builtins.length actualUsers == 1 
                 then builtins.head actualUsers  # This gives us "adrian"
                 else throw "Expected exactly one user with home.nix in homes/home/, found: ${builtins.toString actualUsers}";
  # Create the contextual username
  username = "${baseUsername}-home";  # This gives us "adrian-home"
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
  
  # User configuration - use matching username from home config
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  };
  
  # Home Manager - use the home configuration
  home-manager.users.${username} = import ../../../homes/home/${baseUsername}/home.nix inputs;
  
  # Secrets configuration
  sops.secrets.mysecret = {
    sopsFile = ./secrets.yaml;
    path = "/persist/secrets/mysecret"; # Store secret in the secrets subvolume
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
