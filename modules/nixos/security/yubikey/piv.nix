{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.piv.enable {
    # PIV (Personal Identity Verification) support
    services.pcscd.enable = true;
    
    # PKCS#11 module for YubiKey PIV
    environment.variables = {
      PKCS11_MODULE = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
    };
    
    # Install PIV tools
    environment.systemPackages = with pkgs; [
      yubico-piv-tool
      pkcs11-tools
      opensc
    ];
    
    # Configure OpenSC for YubiKey PIV
    environment.etc."opensc.conf".text = ''
      app default {
        # YubiKey PIV configuration
        reader_driver yubico {
          # Enable PIV applet
          enable_pinpad = false;
        }
        
        framework pkcs15 {
          use_file_caching = true;
          pin_cache_counter = 10;
        }
      }
    '';
    
    # PIV certificate management
    security.pki = {
      certificateFiles = [
        # Add your PIV root certificates here
        # "/path/to/piv-root-ca.crt"
      ];
    };
    
    # Configure browsers for PIV certificates
    programs.firefox.preferences = {
      "security.tls.pkcs11.enable" = true;
      "security.default_personal_cert" = "Ask Every Time";
    };
  };
}
