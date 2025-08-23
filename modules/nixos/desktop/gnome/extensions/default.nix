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
