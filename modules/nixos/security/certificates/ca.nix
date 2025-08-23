{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.certificates.ca.enable {
    # Local CA management
    security.pki = {
      certificateFiles = [
        # "/etc/ssl/certs/local-ca.pem"
      ];
      trustedCertificates = [
        # "/etc/ssl/certs/local-ca.pem"
      ];
    };
    
    # Install CA management tools
    environment.systemPackages = with pkgs; [
      easy-rsa
      cfssl
    ];
  };
}
