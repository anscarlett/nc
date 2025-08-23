# Pure functions for extracting names from filesystem paths
{ lib }:

{
  # Get hostname from hosts/hostname/ path structure
  getHostname = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      # Filter out empty strings and "."
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      # Get the last valid part as hostname
      hostname = lib.last validParts;
    in hostname;

  # Get username from users/username/ path structure  
  getUsername = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      # Filter out empty strings and "."
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      # Get the last valid part as username
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
}