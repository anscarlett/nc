{ config, lib, pkgs, ... }:
{
  imports = [
    ./sudo.nix
    ./groups.nix
  ];
  
  options.mySystem.users = {
    enable = lib.mkEnableOption "user management" // { default = true; };
    
    mainUser = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name";
    };
    
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          isNormalUser = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this is a normal user account";
          };
          
          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional groups for this user";
          };
          
          shell = lib.mkOption {
            type = lib.types.package;
            default = pkgs.zsh;
            description = "Default shell for this user";
          };
          
          openssh.authorizedKeys.keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "SSH authorized keys for this user";
          };
        };
      });
      default = {};
      description = "User accounts to create";
    };
  };
  
  config = lib.mkIf config.mySystem.users.enable {
    users.users = lib.mapAttrs (name: userConfig: {
      isNormalUser = userConfig.isNormalUser;
      extraGroups = [ "wheel" "networkmanager" ] ++ userConfig.extraGroups;
      shell = userConfig.shell;
      openssh.authorizedKeys.keys = userConfig.openssh.authorizedKeys.keys;
    }) config.mySystem.users.users;
    
    # Enable zsh system-wide if any user uses it
    programs.zsh.enable = lib.mkIf (lib.any (user: user.shell == pkgs.zsh) (lib.attrValues config.mySystem.users.users)) true;
    
    # Set default shell programs
    environment.shells = with pkgs; [ bash zsh fish ];
  };
}
