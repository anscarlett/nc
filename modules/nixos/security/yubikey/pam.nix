{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.pam.enable {
    # YubiKey PAM authentication
    security.pam = {
      # Enable U2F authentication
      u2f = {
        enable = true;
        settings = {
          cue = true;
          interactive = true;
        };
      };
      
      # Configure services for YubiKey authentication
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        polkit-1.u2fAuth = true;
        gdm.u2fAuth = true;
        lightdm.u2fAuth = true;
      };
    };
    
    # YubiKey Challenge-Response for offline authentication
    security.pam.yubico = {
      enable = true;
      debug = false;
      mode = "challenge-response";
      
      # Optional: Use YubiCloud for online validation
      # id = "your-yubikey-id";
      # key = "your-api-key";
    };
    
    # Install pamu2fcfg for U2F key registration
    environment.systemPackages = with pkgs; [
      pam_u2f
      pamu2fcfg
    ];
  };
}
