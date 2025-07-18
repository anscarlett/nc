# Core system configuration that applies to all hosts
{ config, pkgs, lib, inputs ? null, ... }: 

let
  # Only use auto-users if inputs are available (for flake-based systems)
  autoUsers = if inputs != null 
    then import ../../lib/auto-users.nix { inherit lib pkgs; }
    else null;
    
  # Auto-create users from homes directory if available
  autoCreatedUsers = if autoUsers != null && builtins.pathExists ../../homes
    then autoUsers.autoCreateUsers {
      homesDir = ../../homes;
      # Default passwords can be overridden in individual hosts
    }
    else {};
    
  # Auto-create home manager users if available  
  autoHomeManagerUsers = if autoUsers != null && inputs != null && builtins.pathExists ../../homes
    then autoUsers.autoCreateHomeManagerUsers {
      homesDir = ../../homes;
      inherit inputs;
    }
    else {};
in {
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

  # User management - automatically created from homes directory
  users.mutableUsers = false;  # Manage users through Nix only
  
  # Auto-create users from home manager configurations
  users.users = autoCreatedUsers;
  
  # Home Manager - auto-assign discovered users
  home-manager.users = autoHomeManagerUsers;
  
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
  system.stateVersion = "25.05";
}
