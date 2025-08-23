{ config, lib, pkgs, ... }:
{
  options.mySystem.system.fonts = {
    enable = lib.mkEnableOption "font configuration" // { default = true; };
    
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        # System fonts
        dejavu_fonts
        liberation_ttf
        
        # Programming fonts
        (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
        
        # Additional fonts
        ubuntu_font_family
        google-fonts
      ];
      description = "Font packages to install";
    };
    
    fontconfig = {
      enable = lib.mkEnableOption "fontconfig" // { default = true; };
      
      defaultFonts = {
        serif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "DejaVu Serif" ];
          description = "Default serif fonts";
        };
        
        sansSerif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "DejaVu Sans" ];
          description = "Default sans-serif fonts";
        };
        
        monospace = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "FiraCode Nerd Font Mono" "DejaVu Sans Mono" ];
          description = "Default monospace fonts";
        };
      };
    };
  };
  
  config = lib.mkIf config.mySystem.system.fonts.enable {
    fonts = {
      packages = config.mySystem.system.fonts.packages;
      
      fontconfig = lib.mkIf config.mySystem.system.fonts.fontconfig.enable {
        enable = true;
        
        defaultFonts = {
          serif = config.mySystem.system.fonts.fontconfig.defaultFonts.serif;
          sansSerif = config.mySystem.system.fonts.fontconfig.defaultFonts.sansSerif;
          monospace = config.mySystem.system.fonts.fontconfig.defaultFonts.monospace;
        };
        
        # Enable font antialiasing
        antialias = true;
        hinting.enable = true;
        subpixel.rgba = "rgb";
      };
    };
  };
}
