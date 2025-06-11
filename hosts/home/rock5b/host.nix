# Rock5B SBC configuration
{ ... }:

let
  btrfsPreset = import ../../../modules/disko-presets/btrfs-flex.nix;
  hostname = "rock5b";
in {
  # Use btrfs-flex disko preset for rock5b
  disko = (btrfsPreset {
    device = "/dev/disk/by-id/rock5b-disk";
    enableImpermanence = false;
    enableHibernate = false;
    swapSize = null;
    luksName = "cryptrock5b";
    enableYubikey = false;
  }).disko;

  system = "aarch64-linux";
  networking.hostName = hostname;
  imports = [
    ../../../common.nix
    # Add any rock5b-specific hardware modules here
  ];
}
