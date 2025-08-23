{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.apparmor.enable {
    # AppArmor configuration
    security.apparmor = {
      enable = true;
      profiles = [
        # Add custom AppArmor profiles here
        # "/etc/apparmor.d/usr.bin.foo"
      ];
      extraConfig = ''
        # AppArmor extra configuration
      '';
    };
    
    # Install AppArmor tools
    environment.systemPackages = with pkgs; [
      apparmor-utils
      apparmor-profiles
    ];
  };
}
