{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.extensions.workspaceIndicator.enable {
    environment.systemPackages = with pkgs; [
      gnomeExtensions.workspace-indicator
    ];
    
    # Configure workspace indicator
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/shell/extensions/workspace-indicator" = {
          position-index = 0;
          panel-position = "left";
        };
      };
    }];
  };
}
