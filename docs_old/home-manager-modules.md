# modules/home-manager/default.nix

```nix
{
  imports = [
    ./desktop
    ./development
    ./shell
  ];
}
```

# modules/home-manager/desktop/default.nix

```nix
{
  imports = [
    ./browsers
    ./editors
    ./terminals
  ];
  
  options.myHome.desktop = {
    enable = lib.mkEnableOption "desktop applications";
  };
}
```

# modules/home-manager/desktop/browsers/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./firefox
    ./chromium
  ];
  
  options.myHome.desktop.browsers = {
    enable = lib.mkEnableOption "web browsers";
    
    default = lib.mkOption {
      type = lib.types.enum [ "firefox" "chromium" "none" ];
      default = "firefox";
      description = "Default web browser";
    };
  };
  
  config = lib.mkIf config.myHome.desktop.browsers.enable {
    # Auto-enable the default browser
    myHome.desktop.browsers.firefox.enable = lib.mkIf (config.myHome.desktop.browsers.default == "firefox") true;
    myHome.desktop.browsers.chromium.enable = lib.mkIf (config.myHome.desktop.browsers.default == "chromium") true;
  };
}
```

# modules/home-manager/desktop/browsers/firefox/default.nix

```nix
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
```

# modules/home-manager/desktop/browsers/firefox/extensions.nix

```nix
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
```

# modules/home-manager/desktop/browsers/firefox/bookmarks.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.desktop.browsers.firefox.bookmarks.enable {
    programs.firefox.profiles.${config.myHome.desktop.browsers.firefox.profile.name} = {
      bookmarks = [
        {
          name = "Development";
          toolbar = true;
          bookmarks = [
            {
              name = "GitHub";
              url = "https://github.com";
            }
            {
              name = "GitLab";
              url = "https://gitlab.com";
            }
            {
              name = "Stack Overflow";
              url = "https://stackoverflow.com";
            }
            {
              name = "MDN Web Docs";
              url = "https://developer.mozilla.org";
            }
          ];
        }
        {
          name = "NixOS";
          toolbar = true;
          bookmarks = [
            {
              name = "NixOS Manual";
              url = "https://nixos.org/manual/nixos/stable/";
            }
            {
              name = "Nixpkgs Manual";
              url = "https://nixos.org/manual/nixpkgs/stable/";
            }
            {
              name = "Home Manager Manual";
              url = "https://nix-community.github.io/home-manager/";
            }
            {
              name = "NixOS Search";
              url = "https://search.nixos.org";
            }
            {
              name = "Nix Package Versions";
              url = "https://lazamar.co.uk/nix-versions/";
            }
          ];
        }
        {
          name = "Tools";
          toolbar = false;
          bookmarks = [
            {
              name = "Regex101";
              url = "https://regex101.com";
            }
            {
              name = "Can I Use";
              url = "https://caniuse.com";
            }
            {
              name = "JSON Formatter";
              url = "https://jsonformatter.curiousconcept.com";
            }
          ];
        }
      ];
    };
  };
}
```

# modules/home-manager/desktop/browsers/firefox/policies.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.desktop.browsers.firefox.policies.enable {
    programs.firefox = {
      policies = {
        # Security policies
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = false;
        DisableFirefoxScreenshots = false;
        
        # Privacy policies
        EnableTrackingProtection = {
          Value = true;
          Locked = false;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        
        # DNS over HTTPS
        DNSOverHTTPS = {
          Enabled = true;
          ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
          Locked = false;
        };
        
        # Certificate policies
        Certificates = {
          Install = [];  # Add custom certificates here if needed
        };
        
        # Extension policies
        ExtensionSettings = {
          # uBlock Origin - force install
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          
          # Bitwarden - allow install
          