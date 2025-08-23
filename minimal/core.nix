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
    vim git curl wget tree htop
    
    # YubiKey tools
    yubikey-manager yubikey-personalization
    
    # Encryption tools
    cryptsetup age sops
    
    # System tools
    pciutils usbutils lshw
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

  # Users configuration - auto-create from users/ directory
  users.mutableUsers = false;
  
  # Auto-discover and create users
  users.users = 
    let
      usersDir = ../users;
      userDirs = if builtins.pathExists usersDir
        then builtins.attrNames (lib.filterAttrs (n: v: v == "directory") (builtins.readDir usersDir))
        else [];
      
      mkUser = username: {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
        shell = pkgs.zsh;
        # Password must be set in host.nix - no default password
      };
    in
      builtins.listToAttrs (map (name: { inherit name; value = mkUser name; }) userDirs);

  # ZSH as default shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Auto-configure Home Manager users
  home-manager.users = 
    let
      usersDir = ../users;
      userDirs = if builtins.pathExists usersDir
        then builtins.attrNames (lib.filterAttrs (n: v: v == "directory") (builtins.readDir usersDir))
        else [];
      
      mkHomeConfig = username:
        let userPath = usersDir + "/${username}/user.nix";
        in if builtins.pathExists userPath then import userPath inputs else {};
    in
      builtins.listToAttrs (map (name: { 
        inherit name; 
        value = mkHomeConfig name;
      }) userDirs);
}