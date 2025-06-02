# Core system configuration that applies to all hosts
{ config, pkgs, lib, ... }: {
  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone
  time.timeZone = "Europe/London";

  # Select internationalisation properties
  i18n.defaultLocale = "en_GB.UTF-8";

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account
  users.mutableUsers = false;  # Manage users through Nix only

  # System-wide packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
  ];

  # Enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # State version
  system.stateVersion = (import ../../lib/constants.nix).nixVersion;
}
