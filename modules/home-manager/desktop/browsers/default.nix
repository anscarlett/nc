{ config, lib, pkgs, ... }:
{
  imports = [
    ./firefox
    ./chromium
  ];
  
  options.myHome.desktop.browsers = {
    enable = lib.mkEnableOption "web browsers";
    
    default = lib.mkOption {
      type = lib.types.enum [ "firefox" "chromium" "none" ];
      default = "firefox";
      description = "Default web browser";
    };
  };
  
  config = lib.mkIf config.myHome.desktop.browsers.enable {
    # Auto-enable the default browser
    myHome.desktop.browsers.firefox.enable = lib.mkIf (config.myHome.desktop.browsers.default == "firefox") true;
    myHome.desktop.browsers.chromium.enable = lib.mkIf (config.myHome.desktop.browsers.default == "chromium") true;
  };
}
