{ config, lib, pkgs, ... }:
{
  options.mySystem.networking.firewall = {
    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "Additional TCP ports to allow";
    };
    
    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "Additional UDP ports to allow";
    };
    
    trustedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Network interfaces to trust completely";
    };
  };
  
  config = lib.mkIf config.mySystem.networking.firewall.enable {
    networking.firewall = {
      enable = true;
      
      # Default allowed ports
      allowedTCPPorts = [ 22 ] ++ config.mySystem.networking.firewall.allowedTCPPorts;
      allowedUDPPorts = config.mySystem.networking.firewall.allowedUDPPorts;
      
      # Trusted interfaces (like VPN)
      trustedInterfaces = config.mySystem.networking.firewall.trustedInterfaces;
      
      # Ping responses
      allowPing = true;
      
      # Log refused connections
      logRefusedConnections = false;
    };
  };
}
