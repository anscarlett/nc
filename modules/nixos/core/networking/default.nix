{ config, lib, pkgs, ... }:
{
  imports = [
    ./wifi.nix
    ./vpn.nix
    ./firewall.nix
  ];
  
  options.mySystem.networking = {
    enable = lib.mkEnableOption "networking configuration" // {
      default = true;
    };
    
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "System hostname";
    };
    
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "System domain name";
    };
    
    enableIPv6 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable IPv6 support";
    };
    
    wifi.enable = lib.mkEnableOption "WiFi support";
    vpn.enable = lib.mkEnableOption "VPN clients";
    firewall.enable = lib.mkEnableOption "firewall" // { default = true; };
  };
  
  config = lib.mkIf config.mySystem.networking.enable {
    networking = {
      hostName = config.mySystem.networking.hostName;
      domain = config.mySystem.networking.domain;
      
      # Enable networkd for systemd-based networking
      useNetworkd = lib.mkDefault true;
      useDHCP = lib.mkDefault false;
      
      # IPv6 configuration
      enableIPv6 = config.mySystem.networking.enableIPv6;
      
      # DNS configuration
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
      
      # Network interfaces
      interfaces = {
        # This will be configured per-host
      };
    };
    
    # Enable systemd-resolved for DNS resolution
    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = lib.mkIf (config.mySystem.networking.domain != null) [ config.mySystem.networking.domain ];
      fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
