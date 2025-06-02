# Create names from paths (e.g., homes/ct/adrian.scarlett -> adrian.scarlett-ct or hosts/ct/laptop -> laptop-ct)
{ lib }:
{
  # Function to get a name from a path with configurable options
  getName = {
    path,            # The path to process
    rootDir,         # The root directory to remove (e.g., "homes" or "hosts")
    fileToRemove,    # The file to remove from path (e.g., "home.nix" or "host.nix")
    reverse ? false  # Whether to reverse the components (true for homes, false for hosts)
  }:
  let
    # Split path into components
    components = lib.splitString "/" path;
    # Remove root directory and file name
    filtered = builtins.filter (x: x != "" && x != rootDir && x != fileToRemove) components;
    # Order components as needed
    ordered = if reverse then lib.lists.reverseList filtered else filtered;
    # Join with hyphens
    name = builtins.concatStringsSep "-" ordered;
  in name;

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
