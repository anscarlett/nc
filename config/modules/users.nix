# User management and shell configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Users configuration - auto-create from users/ directory
  users.mutableUsers = false;
  
  # Auto-discover and create users
  users.users = 
    let
      utils = import ../../lib/utils.nix { inherit lib; };
      validation = import ../../lib/validation.nix { inherit lib; };
      userDirs = builtins.attrNames (utils.discoverDirs ../users);
      
      mkUser = username: {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
        shell = pkgs.zsh;
        # Password must be set in host.nix - no default password for security
      };
      
      baseUsers = builtins.listToAttrs (map (name: { inherit name; value = mkUser name; }) userDirs);
      
      # Merge with any additional users defined in host config
      allUsers = baseUsers // (config.users.users or {});
    in
      # Validate that all users have passwords (in final evaluation)
      validation.validateUserPasswords allUsers;

  # ZSH as default shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Auto-configure Home Manager users
  home-manager.users = 
    let
      utils = import ../../lib/utils.nix { inherit lib; };
      userDirs = builtins.attrNames (utils.discoverDirs ../users);
      
      mkHomeConfig = username:
        let userPath = ../users + "/${username}/user.nix";
        in if builtins.pathExists userPath then import userPath inputs else {};
    in
      builtins.listToAttrs (map (name: { 
        inherit name; 
        value = mkHomeConfig name;
      }) userDirs);
}
