{ config, lib, pkgs, inputs, ... }:

let
  nameFromPath = import "${inputs.public-config}/lib/get-name-from-path.nix" { inherit lib; };
  hostname = nameFromPath.getHostname ./.;  # Gets "work-laptop" from folder structure
in {
  # Import the public core modules
  imports = [
    # Import public modules through inputs
    inputs.public-config.modules.core
    inputs.public-config.modules.desktop.hyprland  # or gnome/kde/dwm
    
    # Add work-specific modules if you create them
    # ../../../work-modules/vpn
    # ../../../work-modules/corporate-ca
  ];

  # Work-specific configuration
  networking.hostName = hostname;  # Automatically set from folder structure: work-laptop
  
  # Example: Corporate VPN (if you have a custom module)
  # services.corporate-vpn.enable = true;
  
  # Work-specific packages
  environment.systemPackages = with pkgs; [
    # Add work-specific applications here
    # teams-for-linux
    # slack
    # zoom-us
    firefox
    vscode
  ];

  # Example: Corporate CA certificates
  # security.ca-certificates.enable = true;
  
  # Example: Secrets management (uncomment when you set up secrets)
  # System-level secrets (managed by NixOS/agenix) - defined in ./secrets.nix
  # age.secrets.work-wifi = {
  #   file = ./work-wifi.age;
  #   owner = "root";
  #   group = "networkmanager";
  #   mode = "0640";
  # };
  # age.secrets.vpn-config = {
  #   file = ./vpn-config.age;
  #   owner = "root";
  #   group = "wheel";
  # };
  # Note: agenix module is automatically included from public-config

  # Users are automatically created by core module from homes directory
  # Override specific settings for this host
  users.users = lib.mkMerge [
    # Auto-created users from core module
    config.users.users
    # Host-specific overrides (uncomment to set password)
    {
      # Set password for the auto-discovered user (your-username-work)
      # your-username-work.hashedPassword = lib.mkForce "$6$rounds=4096$YOUR_GENERATED_HASH_HERE";
    }
  ];
}
