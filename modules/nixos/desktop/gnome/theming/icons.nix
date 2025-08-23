{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.theming.enable {
    # Icon theme configuration
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          icon-theme = config.mySystem.desktop.gnome.theming.iconTheme;
        };
        
        "org/gnome/nautilus/icon-view" = {
          default-zoom-level = "standard";
        };
        
        "org/gnome/nautilus/preferences" = {
          show-image-thumbnails = "always";
        };
      };
    }];
  };
}
