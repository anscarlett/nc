{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.boot.secureBoot.enable {
    # Secure Boot configuration with YubiKey
    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
    };
    
    # YubiKey integration for secure boot
    environment.systemPackages = with pkgs; [
      sbctl
      efibootmgr
    ];
  };
}
