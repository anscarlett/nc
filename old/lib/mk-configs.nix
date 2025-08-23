# Creates configurations from a hierarchical directory structure
{ lib }:
let
  # Recursively find all host.nix or home.nix files
  findConfigs = {
    dir,
    configFile,
    basePath ? dir
  }:
    let
      # Check if directory exists before trying to read it
      dirExists = builtins.pathExists dir;
      contents = if dirExists then builtins.readDir dir else {};
      
      processItem = name: type:
        let
          path = dir + "/${name}";
          relativePath = lib.removePrefix (toString basePath + "/") (toString path);
        in
        if type == "regular" && name == configFile
        then [{
          path = relativePath;
          config = import path;
        }]
        else if type == "directory"
        then findConfigs {
          inherit configFile basePath;
          dir = path;
        }
        else [];
      
      results = lib.flatten (lib.mapAttrsToList processItem contents);
    in results;

  # Convert a relative path to hostname (e.g., "ct/laptop" -> "laptop-ct")
  pathToHostname = path:
    let
      parts = lib.splitString "/" (lib.removeSuffix "/host.nix" path);
      filteredParts = builtins.filter (x: x != "") parts;
    in builtins.concatStringsSep "-" filteredParts;

  # Convert a relative path to username (e.g., "ct/adrian.scarlett" -> "adrian.scarlett-ct") 
  pathToUsername = path:
    let
      parts = lib.splitString "/" (lib.removeSuffix "/home.nix" path);
      filteredParts = builtins.filter (x: x != "") parts;
      reversedParts = lib.reverseList filteredParts;
    in builtins.concatStringsSep "-" reversedParts;
in
{
  # Scan for host configurations
  mkHosts = dir:
    let
      configs = findConfigs {
        inherit dir;
        configFile = "host.nix";
      };
      
      toHostConfig = { path, config }:
        let
          hostname = pathToHostname path;
        in {
          name = hostname;
          value = {
            modules = [ config ];
            # Determine system architecture based on hostname
            system = 
              if lib.hasSuffix "rock5b" hostname then "aarch64-linux"
              else if lib.hasInfix "rpi" hostname || lib.hasInfix "raspberry" hostname then "aarch64-linux"
              else if lib.hasInfix "aarch64" hostname || lib.hasInfix "arm64" hostname then "aarch64-linux"
              else "x86_64-linux";  # Default to x86_64
          };
        };
    in
      builtins.listToAttrs (map toHostConfig configs);

  # Scan for home configurations  
  mkHomes = dir:
    let
      configs = findConfigs {
        inherit dir;
        configFile = "home.nix";
      };
      
      toHomeConfig = { path, config }:
        let
          username = pathToUsername path;
        in {
          name = username;
          value = config;
        };
    in
      builtins.listToAttrs (map toHomeConfig configs);
}
