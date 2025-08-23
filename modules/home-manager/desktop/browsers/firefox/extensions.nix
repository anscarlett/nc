{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.desktop.browsers.firefox.extensions.enable {
    programs.firefox.profiles.${config.myHome.desktop.browsers.firefox.profile.name} = {
      extensions = with pkgs.firefox-addons; [
        # Privacy and security
        ublock-origin
        privacy-badger
        clearurls
        decentraleyes
        
        # Password management
        bitwarden
        
        # Development
        web-developer
        react-devtools
        
        # Productivity
        tree-style-tab
        tab-session-manager
        
        # Dark theme
        darkreader
        
        # GitHub integration
        refined-github
        
        # Video
        sponsorblock
        return-youtube-dislikes
      ];
      
      # Extension-specific settings
      settings = {
        # uBlock Origin
        "extensions.ublock0.advancedUserEnabled" = true;
        "extensions.ublock0.cloudStorageEnabled" = false;
        
        # Privacy Badger
        "extensions.privacy-badger.enabled" = true;
        
        # Dark Reader
        "extensions.darkreader.enabled" = true;
        "extensions.darkreader.theme.mode" = 1;  # Dark mode
        
        # Tree Style Tab
        "extensions.treestyletab.tabbar.style" = "sidebar";
        "extensions.treestyletab.tabbar.position" = "left";
      };
    };
  };
}
