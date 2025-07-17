# Create names from paths (e.g., homes/ct/adrian.scarlett -> adrian.scarlett-ct or hosts/ct/laptop -> laptop-ct)
{ lib }:
let
  # Function to get a name from a path with configurable options
  getName = {
    path,            # The path to process
    rootDir,         # The root directory to remove (e.g., "homes" or "hosts")
    fileToRemove,    # The file to remove from path (e.g., "home.nix" or "host.nix")
    reverse ? false  # Whether to reverse the components (true for homes, false for hosts)
  }:
  let
    # Convert path to string and split into components
    pathStr = toString path;
    components = lib.splitString "/" pathStr;
    # Remove root directory, file name, and any nix store paths
    filtered = builtins.filter (x: 
      x != "" && 
      x != rootDir && 
      x != fileToRemove && 
      !(lib.hasPrefix "nix-store-" x) &&
      !(lib.hasPrefix "/nix/store" x)
    ) components;
    # Order components as needed
    ordered = if reverse then lib.lists.reverseList filtered else filtered;
    # Join with hyphens
    name = builtins.concatStringsSep "-" ordered;
  in name;
in
{
  inherit getName;

  # Convenience function for getting username from homes path
  getUsername = path: 
    getName {
      inherit path;
      rootDir = "homes";
      fileToRemove = "home.nix";
      reverse = true;
    };

  # Convenience function for getting hostname from hosts path
  getHostname = path:
    getName {
      inherit path;
      rootDir = "hosts";
      fileToRemove = "host.nix";
      reverse = false;
    };
}
