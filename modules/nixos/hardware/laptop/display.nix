{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.display.enable {
    # X11 display configuration
    services.xserver = {
      enable = lib.mkDefault true;
      
      # DPI settings for high-DPI displays
      dpi = lib.mkDefault 96;
      
      # Input class sections
      inputClassSections = [
        # Touchpad configuration
        ''
          Identifier "touchpad catchall"
          Driver "libinput"
          MatchIsTouchpad "on"
          MatchDevicePath "/dev/input/event*"
          Option "Tapping" "on"
          Option "TappingButtonMap" "lrm"
          Option "NaturalScrolling" "true"
          Option "ScrollMethod" "twofinger"
          Option "DisableWhileTyping" "true"
          Option "AccelProfile" "adaptive"
        ''
      ];
    };
    
    # Backlight control
    programs.light.enable = true;
    services.actkbd = {
      enable = true;
      bindings = [
        { keys = [ 224 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -U 5"; }
        { keys = [ 225 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -A 5"; }
      ];
    };
    
    # Color temperature adjustment
    services.redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 6500;
        night = 4500;
      };
    };
    
    # Screen rotation for convertible laptops
    hardware.sensor.iio.enable = true;
    
    # Display tools
    environment.systemPackages = with pkgs; [
      brightnessctl
      ddcutil
      autorandr
      arandr
      xorg.xrandr
      wlr-randr  # For Wayland
    ];
    
    # Automatic display configuration
    services.autorandr.enable = true;
    
    # HiDPI support
    console.font = lib.mkIf (config.services.xserver.dpi > 120) "${pkgs.terminus_font}/share/consolefonts/ter-v24n.psf.gz";
    
    # Font scaling for HiDPI
    fonts.fontconfig.defaultFonts = lib.mkIf (config.services.xserver.dpi > 120) {
      serif = [ "DejaVu Serif" ];
      sansSerif = [ "DejaVu Sans" ];
      monospace = [ "DejaVu Sans Mono" ];
    };
  };
}
