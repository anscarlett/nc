# modules/nixos/desktop/default.nix

```nix
{ config, lib, ... }:
{
  imports = [
    ./gnome
    ./hyprland
    ./kde
    ./dwm
  ];
  
  options.mySystem.desktop = {
    enable = lib.mkEnableOption "desktop environment";
    
    environment = lib.mkOption {
      type = lib.types.enum [ "gnome" "hyprland" "kde" "dwm" "none" ];
      default = "none";
      description = "Desktop environment to use";
    };
  };
  
  config = lib.mkIf config.mySystem.desktop.enable {
    # Enable X11 windowing system
    services.xserver.enable = lib.mkDefault true;
    
    # Enable sound with PipeWire
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Auto-enable specific desktop based on selection
    mySystem.desktop.gnome.enable = lib.mkIf (config.mySystem.desktop.environment == "gnome") true;
    mySystem.desktop.hyprland.enable = lib.mkIf (config.mySystem.desktop.environment == "hyprland") true;
    mySystem.desktop.kde.enable = lib.mkIf (config.mySystem.desktop.environment == "kde") true;
    mySystem.desktop.dwm.enable = lib.mkIf (config.mySystem.desktop.environment == "dwm") true;
  };
}
```

# modules/nixos/desktop/gnome/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./extensions
    ./theming
    ./apps
  ];
  
  options.mySystem.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
    
    extensions.enable = lib.mkEnableOption "GNOME extensions" // {
      default = true;
    };
    
    theming.enable = lib.mkEnableOption "GNOME theming" // {
      default = true;
    };
    
    apps.enable = lib.mkEnableOption "GNOME applications" // {
      default = true;
    };
    
    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        gnome-tour
        epiphany
        geary
        totem
        simple-scan
      ];
      description = "GNOME packages to exclude from installation";
    };
  };
  
  config = lib.mkIf config.mySystem.desktop.gnome.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
    
    # Exclude unwanted GNOME packages
    environment.gnome.excludePackages = config.mySystem.desktop.gnome.excludePackages;
    
    # Enable GNOME services
    services.gnome = {
      core-developer-tools.enable = true;
      gnome-keyring.enable = true;
      sushi.enable = true;
      gnome-settings-daemon.enable = true;
    };
    
    # Enable GDM autologin (optional, configure per-host)
    # services.xserver.displayManager.autoLogin = {
    #   enable = false;
    #   user = config.mySystem.users.mainUser;
    # };
    
    # GNOME-specific system packages
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      dconf-editor
      gnome-extension-manager
    ];
    
    # Enable location services for automatic timezone
    services.geoclue2.enable = true;
    
    # Enable automatic screen rotation
    hardware.sensor.iio.enable = true;
  };
}
```

# modules/nixos/desktop/gnome/extensions/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./dash-to-dock.nix
    ./user-themes.nix
    ./workspace-indicator.nix
  ];
  
  options.mySystem.desktop.gnome.extensions = {
    dashToDock.enable = lib.mkEnableOption "Dash to Dock extension";
    userThemes.enable = lib.mkEnableOption "User Themes extension";
    workspaceIndicator.enable = lib.mkEnableOption "Workspace Indicator extension";
    appIndicator.enable = lib.mkEnableOption "AppIndicator extension";
    vitals.enable = lib.mkEnableOption "Vitals system monitor extension";
    clipboardIndicator.enable = lib.mkEnableOption "Clipboard Indicator extension";
  };
  
  config = lib.mkIf config.mySystem.desktop.gnome.extensions.enable {
    environment.systemPackages = with pkgs; [
      gnomeExtensions.user-themes
      gnomeExtensions.tray-icons-reloaded
      gnomeExtensions.vitals
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.appindicator
      gnomeExtensions.bluetooth-quick-connect
      gnomeExtensions.caffeine
      gnomeExtensions.gsconnect
    ] ++ lib.optionals config.mySystem.desktop.gnome.extensions.dashToDock.enable [
      gnomeExtensions.dash-to-dock
    ] ++ lib.optionals config.mySystem.desktop.gnome.extensions.workspaceIndicator.enable [
      gnomeExtensions.workspace-indicator
    ];
  };
}
```

# modules/nixos/desktop/gnome/extensions/dash-to-dock.nix

```nix
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
```

# modules/nixos/desktop/gnome/extensions/user-themes.nix

```nix
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
```

# modules/nixos/desktop/gnome/extensions/workspace-indicator.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.desktop.gnome.extensions.workspaceIndicator.enable {
    environment.systemPackages = with pkgs; [
      gnomeExtensions.workspace-indicator
    ];
    
    # Configure workspace indicator
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/shell/extensions/workspace-indicator" = {
          position-index = 0;
          panel-position = "left";
        };
      };
    }];
  };
}
```

# modules/nixos/desktop/gnome/theming/default.nix

```nix
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
```

# modules/nixos/desktop/gnome/theming/gtk.nix

```nix
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
```

# modules/nixos/desktop/gnome/theming/icons.nix

```nix
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
```

# modules/nixos/desktop/gnome/apps/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./nautilus.nix
    ./terminal.nix
  ];
  
  options.mySystem.desktop.gnome.apps = {
    core = lib.mkEnableOption "core GNOME applications" // { default = true; };
    development = lib.mkEnableOption "development applications";
    media = lib.mkEnableOption "media applications";
    office = lib.mkEnableOption "office applications";
  };
  
  config = lib.mkIf config.mySystem.desktop.gnome.apps.enable {
    environment.systemPackages = with pkgs; [
      # Core GNOME apps (always installed when apps.enable = true)
    ] ++ lib.optionals config.mySystem.desktop.gnome.apps.core [
      # Core applications
      nautilus
      gnome-terminal
      gnome-calculator
      gnome-calendar
      gnome-contacts
      gnome-weather
      gnome-maps
      gnome-clocks
      
      # System utilities
      gnome-system-monitor
      gnome-disk-utility
      gnome-control-center
    ] ++ lib.optionals config.mySystem.desktop.gnome.apps.development [
      # Development tools
      gnome-builder
      devhelp
    ] ++ lib.optionals config.mySystem.desktop.gnome.apps.media [
      # Media applications
      totem
      eog
      evince
      gnome-music
      gnome-photos
    ] ++ lib.optionals config.mySystem.desktop.gnome.apps.office [
      # Office applications
      gnome-text-editor
      file-roller
      gnome-font-viewer
    ];
  };
}
```

# modules/nixos/desktop/gnome/apps/nautilus.nix

```nix
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
```

# modules/nixos/desktop/gnome/apps/terminal.nix

```nix
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
```

# modules/nixos/desktop/hyprland/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./config
    ./keybinds
    ./plugins
  ];
  
  options.mySystem.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland wayland compositor";
    
    nvidia = lib.mkEnableOption "NVIDIA GPU support for Hyprland";
    
    config = {
      enable = lib.mkEnableOption "Hyprland configuration" // { default = true; };
      monitors = lib.mkEnableOption "monitor configuration" // { default = true; };
      workspaces = lib.mkEnableOption "workspace configuration" // { default = true; };
      animations = lib.mkEnableOption "animations" // { default = true; };
    };
    
    keybinds.enable = lib.mkEnableOption "keybind configuration" // { default = true; };
    
    plugins = {
      waybar.enable = lib.mkEnableOption "Waybar status bar" // { default = true; };
      wofi.enable = lib.mkEnableOption "Wofi application launcher" // { default = true; };
      notifications.enable = lib.mkEnableOption "notification daemon" // { default = true; };
    };
  };
  
  config = lib.mkIf config.mySystem.desktop.hyprland.enable {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      enableNvidiaPatches = config.mySystem.desktop.hyprland.nvidia;
    };
    
    # XDG Desktop Portal
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };
    
    # Required packages for Hyprland
    environment.systemPackages = with pkgs; [
      # Hyprland itself
      hyprland
      
      # Session management
      hyprlock
      hypridle
      
      # Utilities
      wl-clipboard
      wlr-randr
      slurp
      grim
      swappy
      
      # File manager
      nautilus
      
      # Terminal
      alacritty
    ];
    
    # Security
    security.pam.services.hyprlock = {};
    
    # Session variables
    environment.sessionVariables = {
      # Wayland
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      
      # Qt
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      
      # GTK
      GDK_BACKEND = "wayland,x11";
      
      # Mozilla
      MOZ_ENABLE_WAYLAND = "1";
      
      # SDL
      SDL_VIDEODRIVER = "wayland";
      
      # Clutter
      CLUTTER_BACKEND = "wayland";
    } // lib.optionalAttrs config.mySystem.desktop.hyprland.nvidia {
      # NVIDIA specific
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
```

# modules/nixos/desktop/hyprland/config/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./monitors.nix
    ./workspaces.nix
    ./animations.nix
  ];
  
  config = lib.mkIf config.mySystem.desktop.hyprland.config.enable {
    # Create Hyprland configuration directory
    environment.etc."hypr/hyprland.conf".text = ''
      # Hyprland configuration generated by NixOS
      
      # Import monitor configuration
      ${lib.optionalString config.mySystem.desktop.hyprland.config.monitors ''
        source = ~/.config/hypr/monitors.conf
      ''}
      
      # Import workspace configuration  
      ${lib.optionalString config.mySystem.desktop.hyprland.config.workspaces ''
        source = ~/.config/hypr/workspaces.conf
      ''}
      
      # Import animation configuration
      ${lib.optionalString config.mySystem.desktop.hyprland.config.animations ''
        source = ~/.config/hypr/animations.conf
      ''}
      
      # Import keybinds
      ${lib.optionalString config.mySystem.desktop.hyprland.keybinds.enable ''
        source = ~/.config/hypr/keybinds.conf
      ''}
      
      # General configuration
      general {
          gaps_in = 5
          gaps_out = 10
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
          allow_tearing = false
      }
      
      # Input configuration
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =
          
          follow_mouse = 1
          
          touchpad {
              natural_scroll = yes
          }
          
          sensitivity = 0
      }
      
      # Decoration
      decoration {
          rounding = 10
          
          blur {
              enabled = true
              size = 3
              passes = 1
          }
          
          drop_shadow = yes
          shadow_range = 4
          shadow_render_power = 3
          col.shadow = rgba(1a1a1aee)
      }
      
      # Misc
      misc {
          force_default_wallpaper = -1
          disable_hyprland_logo = true
      }
    '';
  };
}