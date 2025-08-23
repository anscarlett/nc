# Core system configuration - minimal essentials
{ config, pkgs, lib, inputs, ... }:

{
  # NixOS version
  system.stateVersion = "25.05";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # YubiKey support in initrd
    initrd = {
      availableKernelModules = [ "uas" "usbhid" "usb_storage" ];
      systemd.enable = true;
    };
  };

  # Locale and timezone
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim git curl wget
    
    # YubiKey tools
    yubikey-manager yubikey-personalization
    
    # Encryption tools
    cryptsetup age sops
  ];

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  # YubiKey hardware support
  services.udev.packages = with pkgs; [
    yubikey-personalization
    libfido2
  ];

  # GPG agent for YubiKey
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
