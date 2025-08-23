{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.selinux.enable {
    # SELinux configuration
    security.selinux = {
      enable = true;
      policy = "targeted";
      logLevel = "info";
    };
    
    # Install SELinux tools
    environment.systemPackages = with pkgs; [
      policycoreutils
      selinux-policy
      setools
    ];
  };
}
