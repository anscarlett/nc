{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.theming.enable {
    # GTK configuration
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          # Font settings
          font-name = "Cantarell 11";
          document-font-name = "Cantarell 11";
          monospace-font-name = "FiraCode Nerd Font Mono 10";
          
          # Theme settings
          gtk-theme = config.mySystem.desktop.gnome.theming.gtkTheme;
          
          # UI preferences
          enable-animations = true;
          show-battery-percentage = true;
          clock-show-weekday = true;
          clock-show-seconds = false;
        };
        
        "org/gnome/desktop/wm/preferences" = {
          titlebar-font = "Cantarell Bold 11";
          button-layout = "appmenu:minimize,maximize,close";
        };
      };
    }];
  };
}
