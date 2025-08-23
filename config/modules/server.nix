# Server-specific configuration
{ config, pkgs, lib, ... }:

{
  # Server-specific packages
  environment.systemPackages = with pkgs; [
    htop iotop iftop
    tmux screen
    rsync
    tree lshw pciutils usbutils
  ];

  # Disable unnecessary desktop services
  services.xserver.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  
  # Disable audio services for servers
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio.enable = lib.mkForce false;
  security.rtkit.enable = lib.mkForce false;

  # Server hardening
  security = {
    sudo.enable = true;
    audit.enable = true;
    auditd.enable = true;
  };

  # Firewall configuration
  networking = {
    firewall = {
      enable = true;
      allowPing = false;
      # Add your ports here
      # allowedTCPPorts = [ 80 443 ];
    };
  };

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
  };

  # Automatic updates and cleanup
  system.autoUpgrade = {
    enable = lib.mkDefault false; # Enable manually per server
    dates = "04:00";
  };

  # More aggressive garbage collection for servers
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };
}
