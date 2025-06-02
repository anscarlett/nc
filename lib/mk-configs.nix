# Creates configurations from a hierarchical directory structure
{ lib }:
let
  # Generic function to scan directories for config files
  scanConfigs = {
    dir,              # Root directory to scan
    configFile,       # Name of config file to look for (e.g., "host.nix" or "home.nix")
    getName           # Function to generate name from path
  }:
    let
      # Read directory contents
      contents = builtins.readDir dir;
      
      # Process each item in the directory
      processItem = name: type:
        let
          path = dir + "/${name}";
        in
          if type == "regular" && name == configFile
          then {
            name = getName path;
            value = import path;
          }
          else if type == "directory"
          then scanConfigs {
            inherit configFile getName;
            dir = path;
          }
          else {};

      # Process all items and merge results
      results = lib.mapAttrsToList processItem contents;
    in
      lib.foldl' (acc: item: acc // item) {} results;

  # Import name generation functions
  nameFromPath = import ./get-name-from-path.nix { inherit lib; };
in
{
  # Scan for host configurations
  mkHosts = dir:
    scanConfigs {
      inherit dir;
      configFile = "host.nix";
      getName = nameFromPath.getHostname;
    };

  # Scan for home configurations
  mkHomes = dir:
    scanConfigs {
      inherit dir;
      configFile = "home.nix";
      getName = nameFromPath.getUsername;
    };
}
