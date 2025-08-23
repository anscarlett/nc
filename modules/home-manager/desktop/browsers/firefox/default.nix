{ config, lib, pkgs, ... }:
{
  imports = [
    ./extensions.nix
    ./bookmarks.nix
    ./policies.nix
  ];
  
  options.myHome.desktop.browsers.firefox = {
    enable = lib.mkEnableOption "Firefox browser";
    
    profile = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "default";
        description = "Firefox profile name";
      };
      
      isDefault = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this is the default profile";
      };
    };
    
    extensions.enable = lib.mkEnableOption "Firefox extensions" // { default = true; };
    bookmarks.enable = lib.mkEnableOption "bookmark management" // { default = true; };
    policies.enable = lib.mkEnableOption "security policies" // { default = true; };
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional Firefox preferences";
    };
  };
  
  config = lib.mkIf config.myHome.desktop.browsers.firefox.enable {
    programs.firefox = {
      enable = true;
      
      profiles.${config.myHome.desktop.browsers.firefox.profile.name} = {
        isDefault = config.myHome.desktop.browsers.firefox.profile.isDefault;
        
        # Privacy and security settings
        settings = {
          # Privacy
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.donottrackheader.enabled" = true;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "privacy.clearOnShutdown.formdata" = true;
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.sessions" = false;
          
          # Security
          "security.tls.version.min" = 3;  # TLS 1.2 minimum
          "security.tls.version.max" = 4;  # TLS 1.3 maximum
          "security.webauth.u2f" = true;
          "security.webauth.webauthn" = true;
          
          # Performance
          "browser.cache.disk.enable" = true;
          "browser.cache.memory.enable" = true;
          "browser.sessionhistory.max_entries" = 50;
          
          # UI customization
          "browser.tabs.firefox-view" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.startup.homepage" = "about:home";
          
          # Developer settings
          "devtools.theme" = "dark";
          "devtools.toolbox.host" = "bottom";
          
          # Download settings
          "browser.download.dir" = "/home/${config.home.username}/Downloads";
          "browser.download.useDownloadDir" = true;
          
          # Font settings
          "font.name.serif.x-western" = "Liberation Serif";
          "font.name.sans-serif.x-western" = "Liberation Sans";
          "font.name.monospace.x-western" = "FiraCode Nerd Font Mono";
        } // config.myHome.desktop.browsers.firefox.settings;
      };
    };
  };
}
