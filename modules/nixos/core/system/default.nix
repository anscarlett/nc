{ config, lib, pkgs, ... }:
{
  imports = [
    ./locale.nix
    ./fonts.nix
    ./nix.nix
  ];
  
  options.mySystem.system = {
    enable = lib.mkEnableOption "base system configuration" // { default = true; };
    
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version";
    };
    
    autoUpgrade = {
      enable = lib.mkEnableOption "automatic system upgrades";
      
      allowReboot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow automatic reboots for kernel updates";
      };
      
      channel = lib.mkOption {
        type = lib.types.str;
        default = "nixos-unstable";
        description = "NixOS channel to use for upgrades";
      };
    };
  };
  
  config = lib.mkIf config.mySystem.system.enable {
    system.stateVersion = config.mySystem.system.stateVersion;
    
    # Automatic upgrades
    system.autoUpgrade = lib.mkIf config.mySystem.system.autoUpgrade.enable {
      enable = true;
      allowReboot = config.mySystem.system.autoUpgrade.allowReboot;
      channel = config.mySystem.system.autoUpgrade.channel;
      dates = "weekly";
    };
    
    # Enable documentation
    documentation = {
      enable = true;
      nixos.enable = true;
      man.enable = true;
      info.enable = true;
    };
    
    # Basic system packages
    environment.systemPackages = with pkgs; [
      # System utilities
      curl
      wget
      git
      vim
      nano
      htop
      tree
      unzip
      zip
      rsync
      
      # Network utilities
      dig
      nmap
      tcpdump
      
      # File system utilities
      file
      lsof
      pciutils
      usbutils
    ];
  };
}
