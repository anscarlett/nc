{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.apps.enable {
    # Nautilus file manager configuration
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "list-view";
          search-filter-time-type = "last_modified";
          show-delete-permanently = true;
          show-hidden-files = false;
          show-image-thumbnails = "always";
        };
        
        "org/gnome/nautilus/list-view" = {
          default-column-order = [
            "name"
            "size"
            "type"
            "owner"
            "group"
            "permissions"
            "date_modified"
            "date_accessed"
            "recency"
            "starred"
          ];
          default-visible-columns = [
            "name"
            "size"
            "date_modified"
          ];
        };
      };
    }];
    
    # Install nautilus extensions
    environment.systemPackages = with pkgs; [
      nautilus
      sushi  # File previewer
      nautilus-python
    ];
  };
}
