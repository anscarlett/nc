# Library functions for the NixOS configuration
{ lib }:
{
  # Import and re-export all library functions
  mkConfigs = import ./mk-configs.nix { inherit lib; };
  autoUsers = import ./auto-users.nix { inherit lib; pkgs = null; };
  constants = import ./constants.nix;
  getName = import ./get-name-from-path.nix { inherit lib; };
  validateDevice = import ./validate-device.nix { inherit lib; };
}
