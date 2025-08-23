{ config, lib, pkgs, ... }:
{
  imports = [
    ./systemd-boot.nix
    ./grub.nix  
    ./secure-boot.nix
  ];
  
  options.mySystem.boot = {
    loader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "grub" ];
      default = "systemd-boot";
      description = "Boot loader to use";
    };
    
    secureBoot.enable = lib.mkEnableOption "Secure Boot with YubiKey";
    
    kernel = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.linuxPackages_latest.kernel;
        description = "Kernel package to use";
      };
      
      parameters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional kernel parameters";
      };
    };
  };
  
  config = {
    # Common boot settings that apply to all loaders
    boot = {
      kernelPackages = lib.mkDefault (lib.mkIf (config.mySystem.boot.kernel.package != null) 
        (pkgs.linuxPackagesFor config.mySystem.boot.kernel.package));
      
      kernelParams = config.mySystem.boot.kernel.parameters;
      
      # Enable Plymouth for better boot experience
      plymouth.enable = lib.mkDefault true;
      
      # Optimize boot time
      initrd.systemd.enable = lib.mkDefault true;
    };
  };
}
