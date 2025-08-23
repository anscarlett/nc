{ config, lib, pkgs, ... }:
{
  options.mySystem.users.sudo = {
    enable = lib.mkEnableOption "sudo configuration" // { default = true; };
    
    wheelNeedsPassword = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether wheel group users need password for sudo";
    };
    
    extraRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Additional sudo rules";
    };
  };
  
  config = lib.mkIf config.mySystem.users.sudo.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = config.mySystem.users.sudo.wheelNeedsPassword;
      extraRules = config.mySystem.users.sudo.extraRules;
    };
  };
}
