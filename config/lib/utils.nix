# Pure utility functions for path handling
{ lib }:

{
  # Get hostname from hosts/hostname/ path structure
  getHostname = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      hostname = lib.last validParts;
    in hostname;

  # Get username from users/username/ path structure  
  getUsername = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      username = lib.last validParts;
    in username;

  # Determine system architecture from hostname patterns
  getSystemArch = hostname:
    if lib.hasInfix "rock5b" hostname || 
       lib.hasInfix "rpi" hostname || 
       lib.hasInfix "arm" hostname ||
       lib.hasInfix "aarch64" hostname
    then "aarch64-linux"
    else "x86_64-linux";

  # Extract device identifier for consistent naming
  getDeviceId = hostname:
    lib.replaceStrings ["-" "_" " "] ["" "" ""] (lib.toLower hostname);

  # Discover directories in a path
  discoverDirs = dir:
    if builtins.pathExists dir
    then lib.filterAttrs (n: v: v == "directory") (builtins.readDir dir)
    else {};
}
