{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.input.enable {
    # Libinput configuration
    services.xserver.libinput = {
      enable = true;
      
      # Touchpad settings
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        disableWhileTyping = true;
        middleEmulation = true;
        accelProfile = "adaptive";
        clickMethod = "clickfinger";
      };
      
      # Mouse settings
      mouse = {
        accelProfile = "adaptive";
        naturalScrolling = false;
      };
    };
    
    # Keyboard configuration
    services.xserver.xkb = {
      layout = "us";
      options = "caps:escape";  # Map Caps Lock to Escape
    };
    
    # Input method support
    i18n.inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        uniemoji
      ];
    };
    
    # Gaming input support
    hardware.steam-hardware.enable = lib.mkDefault false;
    
    # Input tools
    environment.systemPackages = with pkgs; [
      libinput
      xinput
      xorg.xev
      evtest
      input-utils
    ];
    
    # Gesture support
    services.touchegg.enable = true;
    
    # Special keys handling
    services.actkbd = {
      enable = true;
      bindings = [
        # Volume controls
        { keys = [ 113 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master toggle"; }
        { keys = [ 114 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master 5%- unmute"; }
        { keys = [ 115 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master 5%+ unmute"; }
        
        # Brightness controls (handled in display.nix)
        
        # Media controls
        { keys = [ 163 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl next"; }
        { keys = [ 165 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl previous"; }
        { keys = [ 164 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl play-pause"; }
      ];
    };
  };
}
