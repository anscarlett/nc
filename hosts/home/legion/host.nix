# Home Legion configuration
inputs: { nixos-hardware, ... }: let
  hostname = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getHostname ./.;
in {
  system = "x86_64-linux";
  networking.hostName = hostname;
  imports = [
    ../../../configuration.nix
    nixos-hardware.nixosModules.lenovo-legion
  ];
}
