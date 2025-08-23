{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.mySystem.boot.loader == "grub") {
    boot.loader = {
      grub = {
        enable = true;
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;
        configurationLimit = 10;
        theme = pkgs.nixos-grub2-theme;
      };
      
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };
}
