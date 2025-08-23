{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.gpg.enable {
    # GPG configuration for YubiKey
    programs.gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = config.mySystem.security.yubikey.ssh.enable;
        pinentryPackage = pkgs.pinentry-gtk2;
        settings = {
          default-cache-ttl = 60;
          max-cache-ttl = 120;
          pinentry-timeout = 10;
        };
      };
    };
    
    # Enable smartcard support
    services.pcscd.enable = true;
    
    # GPG tools
    environment.systemPackages = with pkgs; [
      gnupg
      paperkey
      pgpdump
      parted
    ];
    
    # udev rules for GPG smartcard access
    services.udev.extraRules = ''
      # GPG SmartCard daemon
      SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart pcscd.service"
    '';
    
    # Environment variables for GPG
    environment.shellInit = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
    '';
  };
}
