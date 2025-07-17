# Automatic user creation from home manager configurations
{ lib, pkgs, ... }:

let
  mkConfigs = import ./mk-configs.nix { inherit lib; };
  
  # Extract username from home path (reverse of pathToUsername in mk-configs.nix)
  # Examples:
  # "adrian-home" -> "adrian"  (from homes/home/adrian)
  # "adrianscarlett-ct" -> "adrianscarlett" (from homes/ct/adrianscarlett)
  getUsernameFromHomeName = homeName:
    let
      parts = lib.splitString "-" homeName;
    in
      if lib.length parts >= 2
      then lib.head parts  # Take the first part as the actual username
      else homeName;  # If no dash, use the whole name

  # Extract context from home path
  # Examples:
  # "adrian-home" -> "home"
  # "adrianscarlett-ct" -> "ct"
  getContextFromHomeName = homeName:
    let
      parts = lib.splitString "-" homeName;
    in
      if lib.length parts >= 2
      then lib.last parts  # Take the last part as context
      else "default";

  # Create system users automatically from discovered home configurations
  autoCreateUsers = { 
    homesDir ? ../homes,
    defaultGroups ? [ "wheel" "networkmanager" "audio" "video" ],
    defaultShell ? pkgs.zsh,
    userPasswords ? {},  # Attribute set of username -> hashedPassword
    extraUserConfig ? {}  # Additional per-user config
  }:
    let
      homes = mkConfigs.mkHomes homesDir;
      homeNames = builtins.attrNames homes;
      
      createUser = homeName:
        let
          username = getUsernameFromHomeName homeName;
          context = getContextFromHomeName homeName;
          userConfig = extraUserConfig.${username} or {};
          hashedPassword = userPasswords.${username} or null;
        in {
          name = username;
          value = {
            isNormalUser = true;
            extraGroups = userConfig.extraGroups or defaultGroups;
            shell = userConfig.shell or defaultShell;
            hashedPassword = hashedPassword;
            description = userConfig.description or "User ${username} (${context})";
          } // (builtins.removeAttrs userConfig [ "extraGroups" "shell" "description" ]);
        };
      
      users = map createUser homeNames;
      # Remove duplicates by username (in case multiple contexts have the same user)
      uniqueUsers = lib.unique users;
    in
      builtins.listToAttrs uniqueUsers;

  # Helper to create home-manager user assignments from discovered homes
  autoCreateHomeManagerUsers = {
    homesDir ? ../homes,
    inputs
  }:
    let
      homes = mkConfigs.mkHomes homesDir;
      
      createHomeAssignment = homeName: homeConfig:
        let
          username = getUsernameFromHomeName homeName;
        in {
          name = username;
          value = homeConfig inputs;
        };
    in
      builtins.mapAttrs createHomeAssignment homes;

in {
  inherit 
    getUsernameFromHomeName
    getContextFromHomeName
    autoCreateUsers
    autoCreateHomeManagerUsers;
}
