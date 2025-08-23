{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.networking.wifi.enable {
    networking.wireless = {
      enable = true;
      userControlled.enable = true;
      
      # Use wpa_supplicant for enterprise networks
      environmentFile = "/etc/wpa_supplicant.env";
    };
    
    # Alternative: NetworkManager for easier WiFi management
    # networking.networkmanager = {
    #   enable = true;
    #   wifi.powersave = false;
    # };
    
    # Install WiFi management tools
    environment.systemPackages = with pkgs; [
      wpa_supplicant_gui
      wavemon
      iw
    ];
  };
}
