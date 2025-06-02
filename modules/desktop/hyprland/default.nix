# Hyprland Wayland compositor configuration
{ config, pkgs, lib, ... }: {
  # Import base desktop configuration
  imports = [ ../. ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Wayland-specific packages
  environment.systemPackages = with pkgs; [
    waybar          # Status bar
    swww            # Wallpaper daemon
    swaylock-fancy  # Lock screen
    wl-clipboard    # Clipboard
    mako           # Notification daemon for Wayland
    wofi           # Application launcher
    grim           # Screenshot utility
    slurp          # Screen area selection
  ];

  # Enable XDG portal for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Configure environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # For Electron apps
    MOZ_ENABLE_WAYLAND = "1";  # For Firefox
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
