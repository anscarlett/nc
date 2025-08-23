{ config, lib, pkgs, ... }:
{
  options.mySystem.system.locale = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };
    
    extraLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional locales to generate";
    };
    
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "System timezone";
    };
    
    keyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Console keymap";
    };
  };
  
  config = {
    # Locale configuration
    i18n.defaultLocale = config.mySystem.system.locale.defaultLocale;
    i18n.extraLocaleSettings = lib.mkIf (config.mySystem.system.locale.extraLocales != []) 
      (lib.genAttrs config.mySystem.system.locale.extraLocales (locale: locale));
    
    # Timezone
    time.timeZone = config.mySystem.system.locale.timeZone;
    
    # Console configuration
    console = {
      keyMap = config.mySystem.system.locale.keyMap;
      font = "Lat2-Terminus16";
    };
  };
}
