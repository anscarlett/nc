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
    
    # Find the index of the root directory in the path
    rootIndex = lib.lists.findFirstIndex (x: x == rootDir) null components;
    
    # If we found the root directory, take the components after it
    relevantComponents = if rootIndex != null && rootIndex + 1 < builtins.length components
      then builtins.genList (i: builtins.elemAt components (rootIndex + 1 + i)) 
                           (builtins.length components - rootIndex - 1)
      else [];
    
    # Remove the filename if present
    withoutFile = if relevantComponents != [] && lib.last relevantComponents == fileToRemove
      then lib.init relevantComponents
      else relevantComponents;
    
    # Order components as needed
    ordered = if reverse then lib.lists.reverseList withoutFile else withoutFile;
    
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
