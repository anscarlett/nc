{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.luks.enable {
    # LUKS configuration for YubiKey
    boot.initrd = {
      # Enable YubiKey support in initrd
      availableKernelModules = [ "ykfde" ];
      
      # Install YubiKey tools in initrd
      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.yubikey-personalization}/bin/ykchalresp
        copy_bin_and_libs ${pkgs.openssl}/bin/openssl
      '';
      
      # YubiKey LUKS unlock script
      extraUtilsCommandsTest = ''
        $out/bin/ykchalresp -V
      '';
    };
    
    # Install LUKS YubiKey tools
    environment.systemPackages = with pkgs; [
      cryptsetup
      yubikey-luks
    ];
    
    # systemd service for YubiKey LUKS
    systemd.services.yubikey-luks = {
      description = "YubiKey LUKS unlock service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };
  };
}
