# Server-specific configuration
{ config, pkgs, lib, ... }: {
  # Disable unnecessary desktop services
  services.xserver.enable = false;
  services.printing.enable = false;
  
  # Disable audio services for servers
  services.pipewire.enable = false;
  services.pulseaudio.enable = false;
  security.rtkit.enable = false;

  # Server packages
  environment.systemPackages = with pkgs; [
    htop
    tmux
    iotop
    iftop
  ];

  # Enable fail2ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
  };

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
}
