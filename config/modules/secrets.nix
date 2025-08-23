# Secrets management configuration
{ config, pkgs, lib, ... }:

{
  # SOPS configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    validateSopsFiles = false; # Allow missing secrets files
    
    # Age key management
    age = {
      # Key file location
      keyFile = "/var/lib/sops-nix/key.txt";
      
      # Generate key if it doesn't exist
      generateKey = true;
    };
  };

  # Ensure sops directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0755 root root -"
  ];

  # Tools for secrets management
  environment.systemPackages = with pkgs; [
    sops
    age
  ];

  # Example secret usage (uncomment and customize)
  # sops.secrets.example-secret = {
  #   owner = "root";
  #   group = "wheel";
  #   mode = "0440";
  # };
}
