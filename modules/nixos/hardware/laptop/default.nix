{ config, lib, pkgs, ... }:
{
  imports = [
    ./power-management.nix
    ./display.nix
    ./input.nix
  ];
  
  options.mySystem.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware configuration";
    
    powerManagement.enable = lib.mkEnableOption "laptop power management" // { default = true; };
    display.enable = lib.mkEnableOption "laptop display configuration" // { default = true; };
    input.enable = lib.mkEnableOption "laptop input configuration" // { default = true; };
    
    wifi.enable = lib.mkEnableOption "WiFi support" // { default = true; };
    bluetooth.enable = lib.mkEnableOption "Bluetooth support" // { default = true; };
    
    manufacturer = lib.mkOption {
      type = lib.types.enum [ "generic" "thinkpad" "dell" "hp" "framework" "apple" ];
      default = "generic";
      description = "Laptop manufacturer for specific optimizations";
    };
  };
  
  config = lib.mkIf config.mySystem.hardware.laptop.enable {
    # Enable WiFi
    networking.wireless.enable = lib.mkIf config.mySystem.hardware.laptop.wifi.enable true;
    
    # Bluetooth
    hardware.bluetooth = lib.mkIf config.mySystem.hardware.laptop.bluetooth.enable {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    
    services.blueman.enable = lib.mkIf config.mySystem.hardware.laptop.bluetooth.enable true;
    
    # Audio
    sound.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Graphics
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    
    # Firmware
    hardware.enableRedistributableFirmware = true;
    
    # USB automounting
    services.udisks2.enable = true;
    
    # Manufacturer-specific configurations
    hardware.trackpoint.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "thinkpad") true;
    
    # Framework laptop specific
    hardware.framework.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "framework") true;
    
    # Apple hardware
    hardware.facetimehd.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "apple") true;
    
    # Laptop mode tools
    services.laptop-mode = {
      enable = true;
      powerSupply = "/sys/class/power_supply/ADP1";
      writeCacheTimeout = 60;
    };
    
    # TLP for better battery life
    services.tlp = {
      enable = true;
      settings = {
        # CPU settings
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 80;
        
        # Radio device settings
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        WOL_DISABLE = "Y";
        
        # Battery care
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
        
        # USB settings
        USB_AUTOSUSPEND = 1;
        USB_BLACKLIST_PHONE = 1;
        
        # SATA settings
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";
      };
    };
  };
}
