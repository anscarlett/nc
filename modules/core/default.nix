# Core system configuration that applies to all hosts
{ config, pkgs, lib, ... }: {
  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allow unfree packages (like VSCode)
  nixpkgs.config.allowUnfree = true;

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

  # Basic packages - sound is configured in desktop module

  # User management
  users.mutableUsers = false;  # Manage users through Nix only
  
  # Users are now automatically created from home manager configurations
  # See lib/auto-users.nix for the implementation
  # Individual hosts can override user settings and set passwords
  
  # Enable zsh system-wide
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    # Set a basic prompt
    promptInit = ''
      autoload -U promptinit && promptinit
      autoload -U colors && colors
      setopt PROMPT_SUBST
      PROMPT='%{$fg[green]%}%n@%m%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} %# '
    '';
    
    # Basic shell options
    setOptions = [
      "HIST_VERIFY"
      "SHARE_HISTORY"
      "EXTENDED_HISTORY"
    ];
  };

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

  # YubiKey support for LUKS and authentication
  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  
  # LUKS YubiKey support
  boot.initrd.availableKernelModules = [ "uas" "usbhid" "usb_storage" ];
  
  # Add cryptsetup with YubiKey support to initrd
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.yubikey-luks = {
    description = "YubiKey LUKS unlock";
    wantedBy = [ "cryptsetup.target" ];
    before = [ "cryptsetup.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/sleep 2"; # Wait for YubiKey to be detected
    };
  };

  # State version
  system.stateVersion = (import ../../lib/constants.nix).nixVersion;
}
