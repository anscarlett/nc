{
  imports = [
    ./yubikey
    ./hardening
    ./certificates
  ];
  
  options.mySystem.security = {
    enable = lib.mkEnableOption "security configuration" // { default = true; };
  };
}
