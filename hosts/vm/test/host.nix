# VM configuration
inputs: { nixos-hardware, ... }: let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
  disk = "/dev/disk/by-id/ct-laptop-disk";
  validatedDisk = (import ../../../lib/validate-device.nix) disk;
in {
  # Use btrfs-flex disko preset for ct/laptop
  disko = (btrfsPreset {
    disk = validatedDisk;
    enableImpermanence = true;
    enableHibernate = true;
    swapSize = "32G";
    luksName = "cryptroot";
    enableYubikey = true;
  }).disko;

  networking.hostName = hostname;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
    # nixos-hardware.nixosModules.framework
  ];
}
