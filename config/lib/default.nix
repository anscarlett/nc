# Main library functions
{ lib }:

let
  # Import individual modules
  utils = import ./utils.nix { inherit lib; };
  builders = import ./builders.nix { inherit lib; };
  validation = import ./validation.nix { inherit lib; };
in
  # Export all functions
  utils // builders // validation // {
    # Main configuration builders
    mkNixosConfigurations = builders.mkNixosConfigurations;
    mkHomeConfigurations = builders.mkHomeConfigurations;
    mkDevShells = builders.mkDevShells;
    
    # Utility functions
    getHostname = utils.getHostname;
    getUsername = utils.getUsername;
    getSystemArch = utils.getSystemArch;
  }
