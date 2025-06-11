# CT laptop configuration
inputs: { nixos-hardware, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
in {
  # Use btrfs-flex disko preset for ct/laptop
  disko = (btrfsPreset {
    device = "/dev/disk/by-id/ct-laptop-disk";
    enableImpermanence = true;
    enableHibernate = true;
    swapSize = "32G";
    luksName = "cryptlaptop";
    enableYubikey = true;
  }).disko;

  networking.hostName = hostname;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];  # Add your laptop's profile from nixos-hardware
    # Example for Framework laptop:
    # inputs.nixos-hardware.nixosModules.framework
    # See https://github.com/NixOS/nixos-hardware/blob/master/flake.nix for all profiles
  ];
}
