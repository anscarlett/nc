# CT laptop configuration
inputs: { nixos-hardware, ... }: let
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
in {
  networking.hostName = hostname;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];  # Add your laptop's profile from nixos-hardware
    # Example for Framework laptop:
    # inputs.nixos-hardware.nixosModules.framework
    # See https://github.com/NixOS/nixos-hardware/blob/master/flake.nix for all profiles
  ];
}
