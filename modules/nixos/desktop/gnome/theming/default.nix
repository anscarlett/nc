{ config, lib, pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./icons.nix
  ];
  
  options.mySystem.desktop.gnome.theming = {
    gtkTheme = lib.mkOption {
      type = lib.types.str;
      default = "Adwaita-dark";
      description = "GTK theme to use";
    };
    
    iconTheme = lib.mkOption {
      type = lib.types.str;
      default = "Papirus-Dark";
      description = "Icon theme to use";
    };
    
    cursorTheme = lib.mkOption {
      type = lib.types.str;
      default = "Adwaita";
      description = "Cursor theme to use";
    };
    
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Default wallpaper path";
    };
  };
  
  config = lib.mkIf config.mySystem.desktop.gnome.theming.enable {
    # Install theme packages
    environment.systemPackages = with pkgs; [
      # GTK themes
      adwaita-qt
      adwaita-qt6
      orchis-theme
      arc-theme
      numix-gtk-theme
      
      # Icon themes
      papirus-icon-theme
      numix-icon-theme
      adwaita-icon-theme
      
      # Cursor themes
      vanilla-dmz
      capitaine-cursors
    ];
    
    # Default dconf settings for theming
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = config.mySystem.desktop.gnome.theming.gtkTheme;
          icon-theme = config.mySystem.desktop.gnome.theming.iconTheme;
          cursor-theme = config.mySystem.desktop.gnome.theming.cursorTheme;
          color-scheme = "prefer-dark";
        };
        
        "org/gnome/desktop/background" = lib.mkIf (config.mySystem.desktop.gnome.theming.wallpaper != null) {
          picture-uri = "file://${config.mySystem.desktop.gnome.theming.wallpaper}";
          picture-uri-dark = "file://${config.mySystem.desktop.gnome.theming.wallpaper}";
        };
      };
    }];
  };
}
