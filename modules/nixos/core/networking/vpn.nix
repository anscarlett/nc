{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.networking.vpn.enable {
    # OpenVPN client support
    services.openvpn.servers = {
      # Configuration will be per-host specific
    };
    
    # WireGuard support
    networking.wireguard.enable = true;
    
    # VPN client packages
    environment.systemPackages = with pkgs; [
      openvpn
      wireguard-tools
      networkmanager-openvpn
      networkmanager-vpnc
    ];
  };
}
