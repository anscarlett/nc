# Library functions for the NixOS configuration
{
  auto-users = import ./auto-users.nix;
  get-name-from-path = import ./get-name-from-path.nix;
  mk-configs = import ./mk-configs.nix;
  validate-device = import ./validate-device.nix;
}
