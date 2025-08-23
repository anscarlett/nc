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
