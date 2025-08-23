# Automatic user creation from home manager configurations
{ lib, pkgs, ... }:

let
  mkConfigs = import ./mk-configs.nix { inherit lib; };
  
  # Extract username from home path (reverse of pathToUsername in mk-configs.nix)
  # Examples:
  # "adrian-home" -> "adrian"  (from homes/home/adrian)
  # "adrianscarlett-work" -> "adrianscarlett" (from homes/work/adrianscarlett)
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
  # "adrianscarlett-work" -> "work"
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
    userPasswords ? {},  # Attribute set of full-username -> hashedPassword
    extraUserConfig ? {}  # Additional per-user config
  }:
    let
      homes = mkConfigs.mkHomes homesDir;
      homeNames = builtins.attrNames homes;
      
      createUser = homeName:
        let
          # Use the full context-aware name as the username
          username = homeName;  # e.g., "adrian-home", "adrianscarlett-work"
          baseUsername = getUsernameFromHomeName homeName;  # e.g., "adrian", "adrianscarlett"
          context = getContextFromHomeName homeName;
          userConfig = extraUserConfig.${username} or extraUserConfig.${baseUsername} or {};
          hashedPassword = userPasswords.${username} or userPasswords.${baseUsername} or null;
        in {
          name = username;
          value = {
            isNormalUser = true;
            extraGroups = userConfig.extraGroups or defaultGroups;
            shell = userConfig.shell or defaultShell;
            hashedPassword = hashedPassword;
            description = userConfig.description or "User ${baseUsername} (${context})";
          } // (builtins.removeAttrs userConfig [ "extraGroups" "shell" "description" ]);
        };
      
      users = map createUser homeNames;
    in
      builtins.listToAttrs users;

  # Helper to create home-manager user assignments from discovered homes
  autoCreateHomeManagerUsers = {
    homesDir ? ../homes,
    inputs
  }:
    let
      homes = mkConfigs.mkHomes homesDir;
      
      createHomeAssignment = homeName: homeConfig:
        # Return the home configuration directly - mapAttrs handles the naming
        homeConfig inputs;
    in
      builtins.mapAttrs createHomeAssignment homes;

in {
  inherit 
    getUsernameFromHomeName
    getContextFromHomeName
    autoCreateUsers
    autoCreateHomeManagerUsers;
}
