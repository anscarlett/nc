{ config, lib, pkgs, ... }:
{
  options.mySystem.system.nix = {
    enable = lib.mkEnableOption "Nix daemon configuration" // { default = true; };
    
    flakes = lib.mkEnableOption "experimental flakes support" // { default = true; };
    
    autoOptimiseStore = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically optimize the Nix store";
    };
    
    gc = {
      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };
      
      dates = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "When to run garbage collection";
      };
      
      options = lib.mkOption {
        type = lib.types.str;
        default = "--delete-older-than 30d";
        description = "Garbage collection options";
      };
    };
    
    extraOptions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Nix configuration";
    };
  };
  
  config = lib.mkIf config.mySystem.system.nix.enable {
    nix = {
      package = pkgs.nixFlakes;
      
      settings = {
        # Enable flakes and new command
        experimental-features = lib.mkIf config.mySystem.system.nix.flakes [ "nix-command" "flakes" ];
        
        # Optimize store automatically
        auto-optimise-store = config.mySystem.system.nix.autoOptimiseStore;
        
        # Build settings
        max-jobs = "auto";
        cores = 0;
        
        # Trusted users for multi-user builds
        trusted-users = [ "root" "@wheel" ];
        
        # Binary caches
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      
      # Garbage collection
      gc = lib.mkIf config.mySystem.system.nix.gc.automatic {
        automatic = true;
        dates = config.mySystem.system.nix.gc.dates;
        options = config.mySystem.system.nix.gc.options;
      };
      
      # Extra configuration
      extraOptions = config.mySystem.system.nix.extraOptions;
    };
    
    # Enable nh for better Nix commands
    environment.systemPackages = with pkgs; [
      nh
      nix-output-monitor
      nvd
    ];
  };
}
