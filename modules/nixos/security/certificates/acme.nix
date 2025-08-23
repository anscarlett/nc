{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.certificates.acme.enable {
    # ACME (Let's Encrypt) certificate management
    security.acme = {
      acceptTerms = true;
      email = config.mySystem.security.certificates.acme.email;
      certs = {
        # Example:
        # "example.com" = {
        #   webroot = "/var/www/example.com";
        # };
      };
    };
    
    # Install ACME tools
    environment.systemPackages = with pkgs; [
      dehydrated
      lego
    ];
  };
}
