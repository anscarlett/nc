{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.u2f.enable {
    # U2F authentication support
    hardware.u2f.enable = true;
    
    # Firefox U2F support
    programs.firefox = {
      enable = lib.mkDefault true;
      preferences = {
        "security.webauth.u2f" = true;
        "security.webauth.webauthn" = true;
        "security.webauth.webauthn_enable_softtoken" = false;
        "security.webauth.webauthn_enable_usbtoken" = true;
      };
    };
    
    # Chrome/Chromium U2F support
    programs.chromium = {
      enable = lib.mkDefault true;
      extensions = [
        # U2F extension ID (if needed for older versions)
        # "pfboblefjcgdjicmnffhdgionmgcdmne"
      ];
      extraOpts = {
        # Enable WebAuthn
        "WebAuthenticationProxySupport" = true;
      };
    };
    
    # Install U2F tools
    environment.systemPackages = with pkgs; [
      u2f-host
      libu2f-host
      pamu2fcfg
    ];
    
    # udev rules for U2F devices
    services.udev.packages = with pkgs; [
      libu2f-host
    ];
  };
}
