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
