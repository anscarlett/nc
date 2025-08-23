{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.extensions.userThemes.enable {
    environment.systemPackages = with pkgs; [
      gnomeExtensions.user-themes
    ];
    
    # Enable user themes support
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/shell/extensions/user-theme" = {
          name = "";  # Will be set by theming module
        };
      };
    }];
  };
}
