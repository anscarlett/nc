# Home Legion configuration
inputs: { nixos-hardware, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
in {
  # Use btrfs-flex disko preset for home/legion
  disko = (btrfsPreset {
    device = "/dev/disk/by-id/legion-disk";
    enableImpermanence = true;
    enableHibernate = true;
    swapSize = null;
    luksName = "cryptroot";
    enableYubikey = true;
  }).disko;

  system = "x86_64-linux";
  networking.hostName = hostname;
  imports = [
    ../../../common.nix
    nixos-hardware.nixosModules.lenovo-legion
  ];
    sops.secrets.mysecret = {
    sopsFile = ./secrets.yaml;
    path = "/persist/secrets/mysecret"; # Store secret in the secrets subvolume
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
