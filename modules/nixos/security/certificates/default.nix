{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.certificates.enable {
    # System CA certificates
    security.pki.certificateFiles = [
      # "/etc/ssl/certs/my-root-ca.pem"
      # "/etc/ssl/certs/another-ca.pem"
    ];
    
    # Install certificate management tools
    environment.systemPackages = with pkgs; [
      openssl
      ca-certificates
    ];
    
    # Update CA certificates
    systemd.services.update-ca-certificates = {
      description = "Update CA certificates";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.openssl}/bin/c_rehash /etc/ssl/certs";
      };
    };
  };
}
