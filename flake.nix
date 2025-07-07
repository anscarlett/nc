{
  description = "NixOS system configuration";

  inputs = { 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs: (import ./lib/import-outputs.nix) inputs ./outputs;
}