# GNOME desktop environment configuration
{ config, pkgs, lib, ... }: {
  # Import base desktop configuration
  imports = [ ../. ];

  # Enable GNOME
  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # GNOME-specific packages
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-shell-extensions
  ];

  # Enable common GNOME services
  services.gnome = {
    core-utilities.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
  };
}
