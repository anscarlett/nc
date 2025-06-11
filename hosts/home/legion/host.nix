# Home Legion configuration
inputs: { nixos-hardware, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
in {
  # Use btrfs-flex disko preset for home/legion
  disko = (btrfsPreset {
    device = "/dev/disk/by-id/legion-disk";
    enableImpermanence = false;
    enableHibernate = false;
    swapSize = null;
    luksName = "cryptlegion";
    enableYubikey = false;
  }).disko;

  system = "x86_64-linux";
  networking.hostName = hostname;
  imports = [
    ../../../common.nix
    nixos-hardware.nixosModules.lenovo-legion
  ];
}
