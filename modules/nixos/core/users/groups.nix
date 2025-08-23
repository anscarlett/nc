{ config, lib, pkgs, ... }:
{
  options.mySystem.users.groups = {
    development = lib.mkEnableOption "development groups (docker, libvirtd)";
    media = lib.mkEnableOption "media groups (audio, video)";
    hardware = lib.mkEnableOption "hardware groups (input, lp)";
  };
  
  config = {
    users.groups = lib.mkMerge [
      (lib.mkIf config.mySystem.users.groups.development {
        docker = {};
        libvirtd = {};
      })
      
      (lib.mkIf config.mySystem.users.groups.media {
        audio = {};
        video = {};
      })
      
      (lib.mkIf config.mySystem.users.groups.hardware {
        input = {};
        lp = {};
        scanner = {};
      })
    ];
  };
}
