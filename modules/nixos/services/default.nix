{
  imports = [
    ./web
    ./databases
    ./monitoring
    ./backup
  ];
  
  options.mySystem.services = {
    enable = lib.mkEnableOption "system services";
  };
}
