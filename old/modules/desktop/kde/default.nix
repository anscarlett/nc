# KDE Plasma desktop environment configuration
{ config, pkgs, lib, ... }: {
  # Import base desktop configuration
  imports = [ ../. ];

  # Enable KDE Plasma
  services.xserver = {
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  # KDE-specific packages
  environment.systemPackages = with pkgs; [
    libsForQt5.kate
    libsForQt5.kcalc
    libsForQt5.ark
    libsForQt5.dolphin
    libsForQt5.spectacle  # Screenshot tool
    libsForQt5.okular     # PDF viewer
  ];

  # Enable common KDE services
  programs.kdeconnect.enable = true;  # For phone integration
}
