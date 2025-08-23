{ config, lib, pkgs, ... }:
{
  imports = [
    ./pam.nix
    ./gpg.nix
    ./ssh.nix
    ./luks.nix
    ./u2f.nix
    ./piv.nix
  ];
  
  options.mySystem.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey support";
    
    pam.enable = lib.mkEnableOption "YubiKey PAM authentication";
    gpg.enable = lib.mkEnableOption "YubiKey GPG support";
    ssh.enable = lib.mkEnableOption "YubiKey SSH support";
    luks.enable = lib.mkEnableOption "YubiKey LUKS support";
    u2f.enable = lib.mkEnableOption "YubiKey U2F support";
    piv.enable = lib.mkEnableOption "YubiKey PIV support";
  };
  
  config = lib.mkIf config.mySystem.security.yubikey.enable {
    # Common YubiKey setup
    services.udev.packages = with pkgs; [ 
      yubikey-personalization 
      yubico-piv-tool
    ];
    
    # YubiKey management tools
    environment.systemPackages = with pkgs; [ 
      yubico-piv-tool 
      yubikey-manager 
      yubikey-manager-qt
      yubikey-personalization
      yubikey-personalization-gui
      yubioath-flutter
    ];
    
    # Enable smartcard daemon
    services.pcscd.enable = true;
    
    # udev rules for YubiKey
    services.udev.extraRules = ''
      # YubiKey 4/5 U2F+CCID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 OTP+U2F+CCID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0405", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 U2F
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0402", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 OTP+U2F
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0404", TAG+="uaccess", GROUP="plugdev", MODE="0664"
    '';
  };
}
