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
