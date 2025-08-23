{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.apps.enable {
    # GNOME Terminal configuration
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
          background-color = "rgb(23,20,33)";
          foreground-color = "rgb(208,207,204)";
          palette = [
            "rgb(23,20,33)"
            "rgb(192,28,40)"
            "rgb(38,162,105)"
            "rgb(162,115,76)"
            "rgb(18,72,139)"
            "rgb(163,71,186)"
            "rgb(42,161,179)"
            "rgb(208,207,204)"
            "rgb(94,92,100)"
            "rgb(246,97,81)"
            "rgb(51,218,122)"
            "rgb(233,173,12)"
            "rgb(42,123,222)"
            "rgb(192,97,203)"
            "rgb(51,199,222)"
            "rgb(255,255,255)"
          ];
          use-theme-colors = false;
          use-theme-transparency = false;
          font = "FiraCode Nerd Font Mono 11";
          use-system-font = false;
        };
      };
    }];
  };
}
