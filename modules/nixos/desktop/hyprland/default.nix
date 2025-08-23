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
