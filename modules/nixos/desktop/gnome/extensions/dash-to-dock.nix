{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.extensions.dashToDock.enable {
    environment.systemPackages = with pkgs; [
      gnomeExtensions.dash-to-dock
    ];
    
    # Default dconf settings for Dash to Dock
    # Users can override these in their home-manager configuration
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = "BOTTOM";
          dock-fixed = false;
          intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
          show-mounts = false;
          show-trash = false;
          show-show-apps-button = true;
          click-action = "cycle-windows";
        };
      };
    }];
  };
}
