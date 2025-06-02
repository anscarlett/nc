{
  description = "NixOS system configuration";

  inputs = (import ./lib/import-all.nix) ./inputs;

  outputs = inputs:
    (import ./lib/import-outputs.nix inputs) ./outputs;
}
