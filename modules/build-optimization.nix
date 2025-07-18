# Build caching and optimization configuration
{ lib, config, ... }:
{
  # Enable Nix flakes and new command interface
  nix = {
    settings = {
      # Enable experimental features
      experimental-features = [ "nix-command" "flakes" ];
      
      # Build caching
      builders-use-substitutes = true;
      
      # Optimize builds
      auto-optimise-store = true;
      
      # Use all available cores for building
      max-jobs = "auto";
      cores = 0; # Use all available cores
      
      # Binary caches for faster builds
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    
    # Enable distributed builds if you have multiple machines
    # distributedBuilds = true;
    # buildMachines = [
    #   {
    #     hostName = "build-server";
    #     system = "x86_64-linux";
    #     maxJobs = 4;
    #     speedFactor = 2;
    #     supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #     mandatoryFeatures = [ ];
    #   }
    # ];
  };
  
  # Performance monitoring
  systemd.services.nix-build-monitor = {
    description = "Monitor Nix build performance";
    wantedBy = [ "multi-user.target" ];
    script = ''
      #!/bin/sh
      # Log build statistics
      echo "$(date): Build cache stats" >> /var/log/nix-build-stats.log
      nix store info >> /var/log/nix-build-stats.log 2>&1 || true
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
  
  systemd.timers.nix-build-monitor = {
    description = "Run Nix build monitor daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
