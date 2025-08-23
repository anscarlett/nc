{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.mySystem.boot.loader == "systemd-boot") {
    boot.loader = {
      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 10;
        memtest86.enable = true;
      };
      
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };
}
